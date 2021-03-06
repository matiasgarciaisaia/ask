defmodule Ask.Runtime.Session do
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, QuotaBucket, Respondent, Schedule}
  alias Ask.Runtime.Flow.TextVisitor
  alias Ask.Runtime.{Broker, Flow, Channel, Session, Reply, SurveyLogger, ReplyStep, SessionMode, SessionModeProvider, SMSMode, IVRMode, MobileWebMode, ChannelPatterns}
  use Timex

  defstruct [:current_mode, :fallback_mode, :flow, :respondent, :token, :fallback_delay, :channel_state, :count_partial_results, :schedule]

  @default_fallback_delay 10

  def start(questionnaire, respondent, channel, mode, schedule, retries \\ [], fallback_channel \\ nil, fallback_mode \\ nil, fallback_retries \\ [], fallback_delay \\ @default_fallback_delay, count_partial_results \\ false) do
    flow = Flow.start(questionnaire, mode)
    session = %Session{
      current_mode: SessionModeProvider.new(mode, channel, retries),
      fallback_mode: SessionModeProvider.new(fallback_mode, fallback_channel, fallback_retries),
      flow: flow,
      respondent: respondent,
      fallback_delay: fallback_delay,
      count_partial_results: count_partial_results,
      schedule: schedule
    }
    run_flow(session)
  end

  def default_fallback_delay do
    @default_fallback_delay
  end

  defp mode_start(%Session{flow: flow, respondent: respondent, token: token, current_mode: %SMSMode{channel: channel}} = session) do
    runtime_channel = Ask.Channel.runtime_channel(channel)

    # Is this really necessary?
    Channel.setup(runtime_channel, respondent, token, nil, nil)

    case flow |> Flow.step(session.current_mode |> SessionMode.visitor) do
      {:end, _, reply} ->
        respondent = if Reply.prompts(reply) != [] do
          log_prompts(reply, channel, flow.mode, respondent, true)
          runtime_channel |> Channel.ask(respondent, token, reply)
        else
          respondent
        end
        {:end, reply, respondent}
      {:ok, flow, reply} ->
        log_prompts(reply, channel, flow.mode, respondent)
        respondent = runtime_channel |> Channel.ask(respondent, token, reply)
        {:ok, %{session | flow: flow}, reply, current_timeout(session), respondent}
    end
  end

  defp mode_start(%Session{flow: flow, current_mode: %IVRMode{channel: channel}, respondent: respondent, token: token, schedule: schedule} = session) do

    next_available_date_time = schedule
      |> Schedule.next_available_date_time

    today_end_time = schedule
      |> Schedule.at_end_time(next_available_date_time)

    channel_state = channel
      |> Ask.Channel.runtime_channel
      |> Channel.setup(respondent, token, next_available_date_time, today_end_time)
      |> handle_setup_response

    log_contact("Enqueueing call", channel, flow.mode, respondent)

    session = %{session| channel_state: channel_state}
    {:ok, session, %Reply{}, current_timeout(session), respondent}
  end

  defp mode_start(%Session{flow: flow, respondent: respondent, token: token, current_mode: %MobileWebMode{channel: channel}} = session) do
    runtime_channel = Ask.Channel.runtime_channel(channel)

    # Is this really necessary?
    Channel.setup(runtime_channel, respondent, token, nil, nil)

    reply = mobile_contact_reply(session)

    log_prompts(reply, session.current_mode.channel, flow.mode, session.respondent)
    respondent = runtime_channel |> Channel.ask(respondent, token, reply)
    {:ok, %{session | flow: flow}, reply, current_timeout(session), respondent}
  end

  defp mobile_contact_reply(session) do
    %Reply{
      steps: [
        ReplyStep.new(
          mobile_contact_message(session),
          "Contact")
      ]
    }
  end

  defp mobile_contact_message(%Session{flow: flow, respondent: respondent}) do
    msg = flow.questionnaire.settings["mobile_web_sms_message"] || "Please enter"
    prompts = Ask.Runtime.Step.split_by_newlines(msg)

    prompts
    |> Enum.with_index(1)
    |> Enum.map(fn {prompt, index} ->
      if index == length(prompts) do
       "#{prompt} #{url(respondent.id)}"
      else
       prompt
      end
    end)
  end

  defp url(respondent_id) do
    shorten("#{mobile_base_url()}/mobile_survey/#{respondent_id}?token=#{Respondent.token(respondent_id)}")
  end

  defp mobile_base_url() do
    System.get_env("MOBILE_WEB_BASE_URL") || Ask.Endpoint.url
  end

  defp shorten(url) do
    case Ask.UrlShortener.shorten(url) do
      {:ok, shortened_url} ->
        shortened_url
      {:error, reason} ->
        Ask.Logger.error "Couldn't shorten url. Reason: #{reason}"
        url
      :unavailable ->
        url
    end
  end

  defp current_timeout(%Session{current_mode: %{retries: []}, fallback_delay: fallback_delay}) do
    fallback_delay
  end

  defp current_timeout(%Session{current_mode: %{retries: [next_retry | _]}}) do
    next_retry
  end

  defp run_flow(%{current_mode: current_mode, respondent: respondent} = session) do
    respondent = apply_patterns_if_match(current_mode.channel.patterns, respondent)
    mode_start(%{session | token: Ecto.UUID.generate, respondent: respondent})
  end

  defp apply_patterns_if_match(patterns, respondent) do
    sanitized_number_as_list = Respondent.sanitize_phone_number(respondent.phone_number) |> String.graphemes
    matching_patterns = ChannelPatterns.matching_patterns(patterns, sanitized_number_as_list)
    case matching_patterns do
      [] -> respondent
      [p | _] ->
        sanitized_phone_number = ChannelPatterns.apply_pattern(p, sanitized_number_as_list)
        {:ok, updated_respondent} = respondent |> Respondent.changeset(%{sanitized_phone_number: sanitized_phone_number}) |> Repo.update
        updated_respondent
    end
  end

  defp log_prompts(reply, channel, mode, respondent, force \\ false) do
    if force || !(channel |> Ask.Channel.runtime_channel |> Channel.has_delivery_confirmation?) do
      disposition = Reply.disposition(reply) || respondent.disposition
      Enum.each Reply.steps(reply), fn(step) ->
        step.prompts |> Enum.with_index |> Enum.each(fn {_prompt, index} ->
          SurveyLogger.log(
            respondent.survey_id,
            mode,
            respondent.id,
            respondent.hashed_number,
            channel.id,
            disposition,
            :prompt,
            ReplyStep.title_with_index(step, index + 1))
        end)
      end
    end
  end

  defp log_confirmation(title, disposition, channel, mode, respondent) do
    SurveyLogger.log(respondent.survey_id, mode, respondent.id, respondent.hashed_number, channel.id, disposition, :prompt, title)
  end

  defp log_contact(status, channel, mode, respondent, disposition \\ nil) do
    SurveyLogger.log(respondent.survey_id, mode, respondent.id, respondent.hashed_number, channel.id, disposition || respondent.disposition, :contact, status)
  end

  defp log_response(:answer, channel, mode, respondent, disposition) do
    log_contact("Answer", channel, mode, respondent, disposition)
  end

  defp log_response(:no_reply, channel, mode, respondent, disposition) do
    log_contact("Timeout", channel, mode, respondent, disposition)
  end

  defp log_response({:reply, response}, channel, mode, respondent, disposition) do
    SurveyLogger.log(respondent.survey_id, mode, respondent.id, respondent.hashed_number, channel.id, disposition || respondent.disposition, :response, response)
  end

  defp log_response({:reply_with_step_id, response, _step_id}, channel, mode, respondent, disposition) do
    log_response({:reply, response}, channel, mode, respondent, disposition)
  end

  defp handle_setup_response(setup_response) do
    case setup_response do
      {:ok, new_state} ->
        new_state
      _ ->
        # TODO: handle Channel.setup errors
        nil
    end
  end

  defp clear_token(session) do
    %{session | token: nil}
  end

  def timeout(%{channel_state: channel_state, respondent: respondent} = session) do
    runtime_channel = Ask.Channel.runtime_channel(session.current_mode.channel)

    cond do
      Channel.has_queued_message?(runtime_channel, channel_state) ->
        {:ok, session, %Reply{}, current_timeout(session), respondent}

      Channel.message_expired?(runtime_channel, channel_state) ->
        session = retry(session, runtime_channel)

        next_available_date_time = session.schedule |> Schedule.next_available_date_time

        base_timeout = Interval.new(from: DateTime.utc_now, until: next_available_date_time)
          |> Interval.duration(:minutes)

        {:ok, session, %Reply{}, base_timeout + current_timeout(session), session.respondent}
      true ->
        timeout(session, runtime_channel)
    end
  end

  def timeout(%{current_mode: %{retries: []}, fallback_mode: nil} = session, _) do
    terminate(session)
  end

  def timeout(%{current_mode: %{retries: []}} = session, _) do
    switch_to_fallback_mode(session)
  end

  def timeout(session, runtime_channel) do
    session = session
      |> retry(runtime_channel)
      |> consume_retry()

    # The new session will timeout as defined by hd(retries)
    {:ok, session, %Reply{}, current_timeout(session), session.respondent}
  end

  def terminate(%{current_mode: %SMSMode{}, respondent: respondent} = session) do
    {:stalled, session |> clear_token(), respondent}
  end

  def terminate(%{current_mode: %IVRMode{}, respondent: respondent}) do
    {:failed, respondent}
  end

  def terminate(%{current_mode: %MobileWebMode{}, respondent: respondent} = session) do
    {:stalled, session |> clear_token, respondent}
  end

  def switch_to_fallback_mode(%{fallback_mode: fallback_mode, flow: flow} = session) do
    session = session |> clear_token
    run_flow(%Session{
      session |
      current_mode: fallback_mode,
      fallback_mode: nil,
      channel_state: nil,
      flow: %{
        flow |
        mode: fallback_mode |> SessionMode.mode
      }
    })
  end

  def consume_retry(%{current_mode: %{retries: [_ | retries]}} = session) do
    %{session | current_mode: %{session.current_mode | retries: retries}}
  end

  def retry(session, runtime_channel, reason \\ "Timeout. Call failed.")

  def retry(%{current_mode: %SMSMode{}} = session, runtime_channel, _) do
    token = Ecto.UUID.generate

    {:ok, _flow, reply} = Flow.retry(session.flow, TextVisitor.new("sms"))
    log_prompts(reply, session.current_mode.channel, session.flow.mode, session.respondent)
    respondent = runtime_channel |> Channel.ask(session.respondent, token, reply)
    %{session | token: token, respondent: respondent}
  end

  def retry(%{schedule: schedule, current_mode: %IVRMode{}} = session, runtime_channel, reason) do
    token = Ecto.UUID.generate

    log_contact(reason, session.current_mode.channel, session.flow.mode, session.respondent)

    next_available_date_time = schedule
      |> Schedule.next_available_date_time

    today_end_time = schedule
      |> Schedule.at_end_time(next_available_date_time)

    channel_state = runtime_channel
      |> Channel.setup(session.respondent, token, next_available_date_time, today_end_time)
      |> handle_setup_response()

    %{session | channel_state: channel_state, token: token}
  end

  def retry(%{current_mode: %MobileWebMode{}} = session, runtime_channel, _) do
    token = Ecto.UUID.generate

    reply = mobile_contact_reply(session)
    log_prompts(reply, session.current_mode.channel, session.flow.mode, session.respondent)
    respondent = runtime_channel |> Channel.ask(session.respondent, token, reply)
    %{session | token: token, respondent: respondent}
  end

  def channel_failed(%Session{current_mode: %{retries: []}, fallback_mode: nil} = session, reason) do
    log_contact(reason, session.current_mode.channel, session.flow.mode, session.respondent)
    :failed
  end

  def channel_failed(session, reason) do
    log_contact(reason, session.current_mode.channel, session.flow.mode, session.respondent)
    :ok
  end

  def contact_attempt_expired(session, reason) do
    runtime_channel = Ask.Channel.runtime_channel(session.current_mode.channel)

    session = retry(session, runtime_channel, reason)

    next_available_date_time = session.schedule |> Schedule.next_available_date_time

    base_timeout = Interval.new(from: DateTime.utc_now, until: next_available_date_time)
      |> Interval.duration(:minutes)

    {:ok, session, base_timeout + current_timeout(session)}
  end

  def delivery_confirm(session, title, current_mode) do
    log_confirmation(title, session.respondent.disposition, current_mode.channel, session.flow.mode, session.respondent)
  end

  def sync_step(session, response) do
    sync_step(session, response, session.current_mode)
  end

  def sync_step(session, response, current_mode, want_log_response \\ true) do
    step_answer = Flow.step(session.flow, current_mode |> SessionMode.visitor, response, SessionMode.mode(current_mode))
    respondent = session.respondent

    if want_log_response do
      case step_answer do
        {:end, _, reply} -> log_response(response, current_mode.channel, session.flow.mode, respondent, Reply.disposition(reply))
        {:ok, _flow, reply} -> log_response(response, current_mode.channel, session.flow.mode, respondent, Reply.disposition(reply))
        {:no_retries_left, _flow, reply} -> log_response(response, current_mode.channel, session.flow.mode, respondent, Reply.disposition(reply))
        _ -> :ok
      end
    end

    respondent = store_responses_and_assign_bucket(respondent, step_answer, session)

    session = %{session | respondent: respondent}
    session |> handle_step_answer(step_answer, current_mode)
  end

  defp handle_step_answer(session, {:end, _, reply}, current_mode) do
    log_prompts(reply, current_mode.channel, session.flow.mode, session.respondent, true)
    {:end, reply, session.respondent}
  end

  defp handle_step_answer(session, {:ok, flow, reply}, current_mode) do
    case falls_in_quota_already_completed?(session.respondent, flow) do
      true ->
        session = Broker.update_respondent_disposition(session, "rejected")

        if flow.questionnaire.quota_completed_steps && length(flow.questionnaire.quota_completed_steps) > 0 do
          flow = %{flow | current_step: nil, in_quota_completed_steps: true}
          session = %{session | flow: flow}
          case sync_step(session, :answer, session.current_mode, false) do
            {:ok, session, reply, timeout, respondent} ->
              {:rejected, %{session | respondent: respondent}, reply, timeout, respondent}
            {:end, reply, respondent} ->
              {:rejected, reply, respondent}
            _ ->
              {:rejected, session.respondent}
          end
        else
          {:rejected, session.respondent}
        end
      false ->
        log_prompts(reply, current_mode.channel, flow.mode, session.respondent)
        {:ok, %{session | flow: flow}, reply, current_timeout(session), session.respondent}
    end
  end

  defp handle_step_answer(session, {:no_retries_left, flow, reply}, _) do
    case session do
      %{current_mode: %{retries: []}, fallback_mode: nil} ->
        {:failed, session.respondent}
      _ ->
        {:hangup, %{session | flow: flow}, reply, current_timeout(session), session.respondent}
    end
  end

  defp handle_step_answer(session, {:stopped, _, reply}, current_mode) do
    log_response({:reply, "STOP"}, current_mode.channel, session.flow.mode, session.respondent, reply.disposition)
    {:stopped, reply, session.respondent}
  end

  def cancel(session) do
    Ask.Channel.runtime_channel(session.current_mode.channel)
    |> Channel.cancel_message(session.channel_state)
  end

  def dump(session) do
    %{
      current_mode: session.current_mode |> SessionModeProvider.dump,
      fallback_mode: session.fallback_mode |> SessionModeProvider.dump,
      flow: session.flow |> Flow.dump,
      respondent_id: session.respondent.id,
      token: session.token,
      fallback_delay: session.fallback_delay,
      channel_state: session.channel_state,
      count_partial_results: session.count_partial_results,
      schedule: session.schedule |> Schedule.dump!
    }
  end

  def load(state) do
    %Session{
      current_mode: SessionModeProvider.load(state["current_mode"]),
      fallback_mode: SessionModeProvider.load(state["fallback_mode"]),
      flow: Flow.load(state["flow"]),
      respondent: Repo.get(Ask.Respondent, state["respondent_id"]),
      token: state["token"],
      fallback_delay: state["fallback_delay"],
      channel_state: state["channel_state"],
      count_partial_results: state["count_partial_results"],
      schedule: state["schedule"] |> Schedule.load!
    }
  end

  def current_step_index(session) do
    session.flow.current_step
  end

  def current_step_id(session) do
    flow = session.flow
    if flow && flow.current_step do
      Flow.current_step(flow)["id"]
    else
      nil
    end
  end

  defp store_responses_and_assign_bucket(respondent, {_, _, reply}, session) do
    store_response(respondent, reply)

    try_to_assign_bucket(respondent, session)
  end

  defp store_response(respondent, reply) do
    Reply.stores(reply) |> Enum.each(fn {field_name, value} ->
      existing_responses = respondent
      |> assoc(:responses)
      |> where([r], r.field_name == ^field_name)
      |> Repo.aggregate(:count, :id)

      if existing_responses == 0 do
        respondent
        |> Ecto.build_assoc(:responses, field_name: field_name, value: value)
        |> Repo.insert
      end
    end)
  end

  defp try_to_assign_bucket(respondent, session) do
    survey = (respondent |> Repo.preload(:survey)).survey

    buckets =
      case survey.quota_vars do
        [] -> []
        _ -> Repo.all(from q in QuotaBucket,
               where: q.survey_id == ^survey.id)
      end

    try_to_assign_bucket(respondent, buckets, session)
  end

  defp try_to_assign_bucket(respondent, [], _session) do
    respondent
  end

  defp try_to_assign_bucket(respondent, buckets, session) do
    if respondent.quota_bucket_id do
      respondent
    else
      respondent
        |> sorted_responses()
        |> buckets_matching_responses(buckets)
        |> assign_bucket_if_one_match(respondent, session)
    end
  end

  defp assign_bucket_if_one_match([bucket], respondent, session) do
    respondent = respondent |> Respondent.changeset(%{quota_bucket_id: bucket.id}) |> Repo.update!

    if (session.count_partial_results && respondent.disposition && (respondent.disposition == "partial" || respondent.disposition == "interim partial")) || (respondent.disposition && respondent.disposition == "completed") do
      from(q in QuotaBucket, where: q.id == ^bucket.id) |> Repo.update_all(inc: [count: 1])
    end

    respondent
  end

  defp assign_bucket_if_one_match(_buckets, respondent, _session) do
    respondent
  end

  defp sorted_responses(respondent) do
    (respondent |> Repo.preload(:responses)).responses
      |> Enum.map(fn response ->
        {response.field_name, response.value}
      end) |> Enum.into([]) |> Enum.sort
  end

  defp buckets_matching_responses(responses, buckets) do
    buckets |> Enum.filter(fn bucket ->
      bucket.condition
        |> Map.to_list
        |> Enum.all?(fn {key, value} ->
          responses = responses |> Enum.filter(fn {response_key, _} -> response_key == key end)
          responses != []
            && responses
              |> Enum.all?(fn {_, response_value} ->
                response_value
                  |> QuotaBucket.matches_condition?(value)
              end)
        end)
    end)
  end

  defp falls_in_quota_already_completed?(respondent, flow) do
    cond do
      flow.in_quota_completed_steps -> false
      respondent.quota_bucket_id == nil -> false
      true ->
        bucket = (respondent |> Repo.preload(:quota_bucket)).quota_bucket
        bucket.count >= bucket.quota
    end
  end
end
