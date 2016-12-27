// @flow
import filter from 'lodash/filter'
import findIndex from 'lodash/findIndex'
import reduce from 'lodash/reduce'
import map from 'lodash/map'
import reject from 'lodash/reject'
import concat from 'lodash/concat'
import * as actions from '../actions/questionnaire'
import uuid from 'node-uuid'
import fetchReducer from './fetch'
import * as language from '../language'

const dataReducer = (state: Questionnaire, action): Questionnaire => {
  switch (action.type) {
    case actions.CHANGE_NAME: return changeName(state, action)
    case actions.TOGGLE_MODE: return toggleMode(state, action)
    case actions.ADD_LANGUAGE: return addLanguage(state, action)
    case actions.REMOVE_LANGUAGE: return removeLanguage(state, action)
    case actions.SET_DEFAULT_LANGUAGE: return setDefaultLanguage(state, action)
    case actions.REORDER_LANGUAGES: return reorderLanguages(state, action)
    case actions.SET_SMS_QUESTIONNAIRE_MSG: return setSmsQuestionnaireMsg(state, action)
    case actions.SET_IVR_QUESTIONNAIRE_MSG: return setIvrQuestionnaireMsg(state, action)
    case actions.UPLOAD_CSV_FOR_TRANSLATION: return uploadCsvForTranslation(state, action)
    default: return steps(state, action)
  }
}

const steps = (state, action) => {
  // Up to now we've been assuming that all content was under corresponding 'en' keys,
  // now that languages can be added and removed and default language can be
  // set to whatever the user wants, that assumption is not safe anymore.
  // Moreover, most of the actions that the stepsReducer needs to handle will need
  // questionnaire level knowledge, namely the set of all questionnaire languages
  // and the questionnaire's default language.
  // Given we are on a tight schedule, I chose to pass the questionnaire down
  // to the stepsReducer in a separate variable so there are no conflicts.
  // That's the `state` argument added to the stepsReducer call.
  // Multilanguage has impacted the application much more thoroughly than we had
  // anticipated, this is a compromise solution that should be revised.
  const newSteps = state.steps == null ? [] : stepsReducer(state.steps, action, state)

  if (newSteps !== state.steps) {
    return {
      ...state,
      steps: newSteps
    }
  } else {
    return state
  }
}

const stepsReducer = (state, action, quiz: Questionnaire) => {
  switch (action.type) {
    case actions.ADD_STEP: return addStep(state, action)
    case actions.MOVE_STEP: return moveStep(state, action)
    case actions.MOVE_STEP_TO_TOP: return moveStepToTop(state, action)
    case actions.CHANGE_STEP_TITLE: return changeStepTitle(state, action)
    case actions.CHANGE_STEP_TYPE: return changeStepType(state, action)
    case actions.CHANGE_STEP_PROMPT_SMS: return changeStepSmsPrompt(state, action, quiz)
    case actions.CHANGE_STEP_PROMPT_IVR: return changeStepIvrPrompt(state, action, quiz)
    case actions.CHANGE_STEP_AUDIO_ID_IVR: return changeStepIvrAudioId(state, action, quiz)
    case actions.CHANGE_STEP_STORE: return changeStepStore(state, action)
    case actions.DELETE_STEP: return deleteStep(state, action)
    case actions.ADD_CHOICE: return addChoice(state, action)
    case actions.DELETE_CHOICE: return deleteChoice(state, action)
    case actions.CHANGE_CHOICE: return changeChoice(state, action, quiz)
    case actions.CHANGE_NUMERIC_RANGES: return changeNumericRanges(state, action)
    case actions.CHANGE_RANGE_SKIP_LOGIC: return changeRangeSkipLogic(state, action)
  }

  return state
}

const addChoice = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    choices: [
      ...step.choices,
      {
        value: '',
        responses: {
          ivr: [],
          sms: {
            'en': []
          }
        },
        skipLogic: null
      }
    ]
  }))
}

const deleteChoice = (state, action) => {
  return changeStep(state, action.stepId, (step) => ({
    ...step,
    choices: [
      ...step.choices.slice(0, action.index),
      ...step.choices.slice(action.index + 1)
    ]
  }))
}

const changeChoice = (state, action, quiz: Questionnaire) => {
  let smsValues = action.choiceChange.smsValues
  let ivrValues = action.choiceChange.ivrValues
  if (action.choiceChange.autoComplete && smsValues == '' && ivrValues == '') {
    [smsValues, ivrValues] = autoComplete(state, action.choiceChange.response, quiz)
  }

  return changeStep(state, action.stepId, (step) => {
    const previousChoices = step.choices.slice(0, action.choiceChange.index)
    const choice = step.choices[action.choiceChange.index]
    const nextChoices = step.choices.slice(action.choiceChange.index + 1)
    return ({
      ...step,
      choices: [
        ...previousChoices,
        {
          ...choice,
          value: action.choiceChange.response,
          responses: {
            ...choice.responses,
            ivr: splitValues(ivrValues),
            sms: {
              ...choice.responses.sms,
              [quiz.defaultLanguage]: splitValues(smsValues)
            }
          },
          skipLogic: action.choiceChange.skipLogic
        },
        ...nextChoices
      ]
    })
  })
}

const autoComplete = (state, value, quiz: Questionnaire) => {
  let setted = false

  let smsValues = ''
  let ivrValues = ''

  state.forEach((step) => {
    if ((step.type === 'multiple-choice') && !setted) {
      step.choices.forEach((choice) => {
        if (choice.value == value && !setted) {
          setted = true

          if (choice.responses.sms && choice.responses.sms[quiz.defaultLanguage]) {
            smsValues = choice.responses.sms[quiz.defaultLanguage].join(',')
          }

          if (choice.responses.ivr) {
            ivrValues = choice.responses.ivr.join(',')
          }
        }
      })
    }
  })
  return [smsValues, ivrValues]
}

const splitValues = (values) => {
  return values.split(',').map((r) => r.trim()).filter(r => r.length != 0)
}

const deleteStep = (state, action) => {
  return filter(state, s => s.id != action.stepId)
}

const moveStep = (state, action) => {
  const stepToMove = state[findIndex(state, s => s.id === action.sourceStepId)]
  const stepAbove = state[findIndex(state, s => s.id === action.targetStepId)]

  const move = (accum, step) => {
    if (step.id != stepToMove.id) {
      accum.push(step)
    }

    if (step.id === stepAbove.id) {
      accum.push(stepToMove)
    }

    return accum
  }

  return reduce(state, move, [])
}

const moveStepToTop = (state, action) => {
  const stepToMove = state[findIndex(state, s => s.id === action.stepId)]
  return concat([stepToMove], reject(state, s => s.id === action.stepId))
}

function changeStep<T: Step>(state, stepId, func: (step: Object) => T) {
  const stepIndex = findIndex(state, s => s.id == stepId)

  return [
    ...state.slice(0, stepIndex),
    func(state[stepIndex]),
    ...state.slice(stepIndex + 1)
  ]
}

type ActionChangeStepSmsPrompt = {
  stepId: string,
  newPrompt: string
};

const changeStepSmsPrompt = (state, action: ActionChangeStepSmsPrompt, quiz: Questionnaire): Step[] => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    prompt: {
      ...step.prompt,
      [quiz.defaultLanguage]: {
        ...step.prompt[quiz.defaultLanguage],
        sms: action.newPrompt
      }
    }
  }))
}

const changeStepIvrPrompt = (state, action, quiz: Questionnaire) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    prompt: {
      ...step.prompt,
      [quiz.defaultLanguage]: {
        ...step.prompt[quiz.defaultLanguage],
        ivr: {
          ...(step.prompt[quiz.defaultLanguage] ? step.prompt[quiz.defaultLanguage].ivr : {}),
          text: action.newPrompt.text,
          audioSource: action.newPrompt.audioSource
        }
      }
    }
  }))
}

const changeStepIvrAudioId = (state, action, quiz: Questionnaire) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    prompt: {
      ...step.prompt,
      [quiz.defaultLanguage]: {
        ...step.prompt[quiz.defaultLanguage],
        ivr: {
          ...step.prompt[quiz.defaultLanguage].ivr,
          audioId: action.newId,
          audioSource: 'upload'
        }
      }
    }
  }))
}

const changeStepTitle = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    title: action.newTitle
  }))
}

const clearTypeProperties = (step: Step): BaseStep => {
  return {
    id: step.id,
    title: step.title,
    prompt: step.prompt,
    store: step.store
  }
}

const changeStepType = (state, action) => {
  switch (action.stepType) {
    case 'multiple-choice':
      return changeStep(state, action.stepId, step => {
        let baseStep = clearTypeProperties(step)
        return {
          ...baseStep,
          type: action.stepType,
          choices: []
        }
      })
    case 'numeric':
      return changeStep(state, action.stepId, step => {
        let baseStep = clearTypeProperties(step)
        return {
          ...baseStep,
          type: action.stepType,
          minValue: null,
          maxValue: null,
          rangesDelimiters: null,
          ranges: [{from: null, to: null, skipLogic: null}]
        }
      })
    default:
      throw new Error(`unknown step type: ${action.stepType}`)
  }
}

const changeStepStore = (state, action) => {
  return changeStep(state, action.stepId, step => ({
    ...step,
    store: action.newStore
  }))
}

const addStep = (state, action) => {
  return [
    ...state,
    newMultipleChoiceStep()
  ]
}

const newLanguageSelectionStep = (first: string, second: string): LanguageSelectionStep => {
  return {
    id: uuid.v4(),
    type: 'language-selection',
    title: 'Language selection',
    store: 'language',
    prompt: {
      'en': {
        sms: '',
        ivr: {
          text: '',
          audioSource: 'tts'
        }
      }
    },
    languageChoices: [null, first, second]
  }
}

const newMultipleChoiceStep = () => {
  return {
    id: uuid.v4(),
    type: 'multiple-choice',
    title: '',
    store: '',
    prompt: {
      'en': {
        sms: '',
        ivr: {
          text: '',
          audioSource: 'tts'
        }
      }
    },
    choices: []
  }
}

const toggleMode = (state, action) => {
  let modes = state.modes
  if (modes.indexOf(action.mode) == -1) {
    modes = modes.slice()
    modes.push(action.mode)
  } else {
    modes = modes.filter(mode => mode != action.mode)
  }
  return {
    ...state,
    modes
  }
}

type ActionChangeName = {
  newName: string
};

const changeName = (state: Questionnaire, action: ActionChangeName): Questionnaire => {
  return {
    ...state,
    name: action.newName
  }
}

const addLanguage = (state, action) => {
  if (state.languages.indexOf(action.language) == -1) {
    let steps
    if (state.languages.length == 1) {
      steps = addLanguageSelectionStep(state, action)
    } else {
      steps = addOptionToLanguageSelectionStep(state, action.language)
    }
    return {
      ...state,
      steps: steps,
      languages: [...state.languages, action.language]
    }
  } else {
    return state
  }
}

const removeLanguage = (state, action) => {
  const indexToDelete = state.languages.indexOf(action.language)
  if (indexToDelete != -1) {
    const newLanguages = [...state.languages.slice(0, indexToDelete), ...state.languages.slice(indexToDelete + 1)]
    let newSteps = removeOptionFromLanguageSelectionStep(state, action.language)

    // If only one language remains, remove the language-selection
    // step (should be the first one)
    if (newLanguages.length == 1 && state.languages.length > 1) {
      newSteps = newSteps.slice(1)
    }

    return {
      ...state,
      steps: newSteps,
      languages: newLanguages
    }
  } else {
    return state
  }
}

const reorderLanguages = (state, action) => {
  let languageSelectionStep = state.steps[0]

  if (languageSelectionStep.type === 'language-selection') {
    let choices = languageSelectionStep.languageChoices

    var index = choices.indexOf(action.language)
    if (index > -1) {
      choices.splice(index, 1)
      choices.splice(action.index, 0, action.language)
    }

    return {
      ...state,
      steps: changeStep(state.steps, state.steps[0].id, (step) => ({
        ...step,
        languageChoices: choices
      }))
    }
  } else {
    return state
  }
}

const setQuestionnaireMsg = (state, action, mode) => {
  let questionnaireMsg
  let defaultLanguageMsg
  questionnaireMsg = Object.assign({}, state[action.msgKey])
  if (state[action.msgKey] && state[action.msgKey][state.defaultLanguage]) {
    defaultLanguageMsg = questionnaireMsg[state.defaultLanguage]
  } else {
    defaultLanguageMsg = {}
    questionnaireMsg[state.defaultLanguage] = defaultLanguageMsg
  }
  defaultLanguageMsg[mode] = action.msg
  let newState = {...state}
  newState[action.msgKey] = questionnaireMsg
  return newState
}

const setIvrQuestionnaireMsg = (state, action) => {
  return setQuestionnaireMsg(state, action, 'ivr')
}

const setSmsQuestionnaireMsg = (state, action) => {
  return setQuestionnaireMsg(state, action, 'sms')
}

const addOptionToLanguageSelectionStep = (state, language) => {
  return changeStep(state.steps, state.steps[0].id, (step) => ({
    ...step,
    languageChoices: [
      ...step.languageChoices,
      language
    ]
  }))
}

const removeOptionFromLanguageSelectionStep = (state, language) => {
  const languageSelectionStep = state.steps[0]

  if (languageSelectionStep.type === 'language-selection') {
    const choices = languageSelectionStep.languageChoices
    const index = choices.indexOf(language)

    const newLanguages = [...choices.slice(0, index), ...choices.slice(index + 1)]

    return changeStep(state.steps, languageSelectionStep.id, (step) => ({
      ...step,
      languageChoices: newLanguages
    }))
  } else {
    return state.steps
  }
}

const addLanguageSelectionStep = (state, action) => {
  return [
    newLanguageSelectionStep(state.languages[0], action.language),
    ...state.steps
  ]
}

const setDefaultLanguage = (state, action) => {
  return {
    ...state,
    defaultLanguage: action.language
  }
}

type ValidationState = {
  data: Questionnaire,
  errors: { [path: string]: string[] }
};

const validateReducer = (reducer) => {
  // React will call this with an undefined the first time for initialization.
  // We mimic that in the specs, so ValidationState needs to become optional here.
  return (state: ?ValidationState, action: any) => {
    const newState = reducer(state, action)
    validate(newState)
    return newState
  }
}

const validate = (state: ValidationState) => {
  if (!state.data) return
  state.errors = {}
  const context = {
    sms: state.data.modes.indexOf('sms') != -1,
    ivr: state.data.modes.indexOf('ivr') != -1,
    defaultLanguage: state.data.defaultLanguage,
    languages: state.data.languages,
    errors: state.errors
  }

  validateSteps('steps', state.data.steps, context)
}

const validateSteps = (path, steps, context) => {
  for (let i = 0; i < steps.length; i++) {
    validateStep(`${path}[${i}]`, steps[i], context)
  }
}

const validateStep = (path, step, context) => {
  if (context.sms &&
      (!step.prompt[context.defaultLanguage] ||
      !step.prompt[context.defaultLanguage].sms ||
      isBlank(step.prompt[context.defaultLanguage].sms))) {
    addError(context, `${path}.prompt.sms`, 'SMS prompt must not be blank')
  }

  if (context.ivr &&
      step.prompt[context.defaultLanguage] &&
      step.prompt[context.defaultLanguage].ivr &&
      step.prompt[context.defaultLanguage].ivr.audioSource == 'tts' &&
      isBlank(step.prompt[context.defaultLanguage].ivr.text)) {
    addError(context, `${path}.prompt.ivr.text`, 'Voice prompt must not be blank')
  }

  if (step.type === 'multiple-choice') {
    validateChoices(`${path}.choices`, step.choices, context)
  }
}

const validateChoices = (path, choices: Choice[], context) => {
  if (choices.length < 2) {
    addError(context, path, 'You should define at least two response options')
  }

  for (let i = 0; i < choices.length; i++) {
    validateChoice(`${path}[${i}]`, choices[i], context)
  }

  const values = []
  let sms = []
  let ivr = []
  for (let i = 0; i < choices.length; i++) {
    let choice = choices[i]
    if (values.includes(choice.value)) {
      addError(context, `${path}[${i}].value`, 'Value already used in a previous response')
    }

    if (choice.responses.sms && choice.responses.sms[context.defaultLanguage]) {
      for (let choiceSms of choice.responses.sms[context.defaultLanguage]) {
        if (sms.includes(choiceSms)) {
          addError(context, `${path}[${i}].sms`, `Value "${choiceSms}" already used in a previous response`)
        }
      }
      sms.push(...choice.responses.sms[context.defaultLanguage])
    }

    if (choice.responses.ivr) {
      for (let choiceIvr of choice.responses.ivr) {
        if (ivr.includes(choiceIvr)) {
          addError(context, `${path}[${i}].ivr`, `Value "${choiceIvr}" already used in a previous response`)
        }
      }
      ivr.push(...choice.responses.ivr)
    }

    values.push(choice.value)
  }
}

const validateChoice = (path, choice: Choice, context) => {
  if (isBlank(choice.value)) {
    addError(context, `${path}.value`, 'Response must not be blank')
  }

  if (context.sms &&
      choice.responses.sms &&
      choice.responses.sms[context.defaultLanguage] &&
      choice.responses.sms[context.defaultLanguage].length == 0) {
    addError(context, `${path}.sms`, 'SMS must not be blank')
  }

  if (context.ivr) {
    if (choice.responses.ivr &&
        choice.responses.ivr.length == 0) {
      addError(context, `${path}.ivr`, '"Phone call" must not be blank')
    }

    if (choice.responses.ivr &&
        choice.responses.ivr.some(value => !value.match('^[0-9#*]*$'))) {
      addError(context, `${path}.ivr`, '"Phone call" must only consist of single digits, "#" or "*"')
    }
  }
}

const addError = (context, path, error) => {
  context.errors[path] = context.errors[path] || []
  context.errors[path].push(error)
}

const isBlank = (value: string) => {
  return !value || value.trim().length == 0
}

export const stepStoreValues = (questionnaire: Questionnaire) => {
  const multipleChoiceSteps = reject(questionnaire.steps, (step) =>
    step.type == 'language-selection'
  )

  return reduce(multipleChoiceSteps, (options, step) => {
    options[step.store] = {
      type: step.type,
      values: map(step.choices, (choice) =>
        choice.value
      )
    }
    return options
  }, {})
}

export const csvForTranslation = (questionnaire: Questionnaire) => {
  const defaultLang = questionnaire.defaultLanguage
  const nonDefaultLangs = filter(questionnaire.languages, lang => lang !== defaultLang)

  // First column is the default lang, then the rest of the langs
  const headers = concat([defaultLang], nonDefaultLangs)
  let languageNames = headers.map(h => language.codeToName(h))
  let rows = [languageNames]

  // Keep a record of exported strings to avoid dups
  let exported = {}
  let context = {rows, headers, exported}

  questionnaire.steps.forEach(step => {
    if (step.type !== 'language-selection') {
      // Sms Prompt
      let defaultSms = ((step.prompt[defaultLang] || {}).sms || '').trim()
      addToCsvForTranslation(defaultSms, context, lang =>
        (step.prompt[lang] || {}).sms || ''
      )

      // Ivr Prompt
      let defaultIvr = (((step.prompt[defaultLang] || {}).ivr || {}).text || '').trim()
      addToCsvForTranslation(defaultIvr, context, lang =>
        ((step.prompt[lang] || {}).ivr || {}).text || ''
      )

      // Sms Prompt. Note IVR responses shouldn't be translated because it is expected to be a digit.
      if (step.type === 'multiple-choice') {
        step.choices.forEach(choice => {
          // Response sms
          const defaultResponseSms = ((choice.responses.sms || {})[defaultLang] || []).join(', ').trim()
          addToCsvForTranslation(defaultResponseSms, context, lang =>
            ((choice.responses.sms || {})[lang] || []).join(', ')
          )
        })
      }
    }
  })

  const q = questionnaire.quotaCompletedMsg
  if (q) {
    addMessageToCsvForTranslation(q, defaultLang, context)
  }

  const e = questionnaire.errorMsg
  if (e) {
    addMessageToCsvForTranslation(e, defaultLang, context)
  }

  return rows
}

const addMessageToCsvForTranslation = (m, defaultLang, context) => {
  let defaultSmsCompletedMsg = ((m[defaultLang] || {}).sms || '').trim()
  addToCsvForTranslation(defaultSmsCompletedMsg, context, lang =>
    (m[lang] || {}).sms || ''
  )

  let defaultIvrCompletedMsg = (((m[defaultLang] || {}).ivr || {}).text || '').trim()
  addToCsvForTranslation(defaultIvrCompletedMsg, context, lang =>
    ((m[lang] || {}).ivr || {}).text || ''
  )
}

export const csvTranslationFilename = (questionnaire: Questionnaire): string => {
  const filename = (questionnaire.name || '').replace(/\W/g, '')
  return filename + '_translations.csv'
}

const addToCsvForTranslation = (text, context, func) => {
  if (text.length != 0 && !context.exported[text]) {
    context.exported[text] = true
    context.rows.push(context.headers.map(func))
  }
}

export default validateReducer(fetchReducer(actions, dataReducer))

const changeNumericRanges = (state, action) => {
  return changeStep(state, action.stepId, step => {
    // validate
    let rangesDelimiters = action.rangesDelimiters
    let minValue: ?number = action.minValue ? parseInt(action.minValue) : null
    let maxValue: ?number = action.maxValue ? parseInt(action.maxValue) : null
    let values: Array<number> = []

    if (minValue != null) {
      values.push(minValue)
    }
    if (rangesDelimiters) {
      let delimiters = rangesDelimiters.split(',')
      values = values.concat(delimiters.map((e) => { return parseInt(e) }))
    }
    if (maxValue != null) {
      values.push(maxValue)
    }

    let isValid = true
    let i = 0
    while (isValid && i < values.length - 1) {
      isValid = values[i] < values[i + 1]
      i++
    }

    if (!isValid) {
      return {
        ...step,
        minValue: minValue,
        maxValue: maxValue,
        rangesDelimiters: rangesDelimiters
      }
    }

    // Just to please Flow...
    let auxValues: Array<?number> = values.map(n => n)

    // generate ranges
    if (minValue == null) {
      auxValues.unshift(null)
    }
    if (maxValue != null) {
      auxValues.pop()
    }

    let ranges = []
    for (let [i, from] of auxValues.entries()) {
      // P1. From the `for` expression above we know `0 <= i < auxValues.length`
      //
      // P2. Precondition: there may only be a null element at the 0th position of
      // `auxValues`. At the moment of writing this comment the code above satisfies
      // this assertion.
      //
      // Here we'll compute the `to` end of the current range.
      let to
      if (i == auxValues.length - 1) {
        // P3. We're at the end of the `auxValues` array, which means we're computing
        // the last range, which MUST end with `maxValue`.
        to = maxValue
      } else {
        // P4. We are not at the end of the array.
        // 4a. Because of `P4`, the `to` end of the current range is
        // the `from` in `auxValues` minus 1, so there's no overlap. Note that
        // since `i + 1 > 0` (see `P1`), `auxValues[i+1]` is guaranteed to be not null (see `P2`).
        const nextFrom = auxValues[i + 1]
        // 4b. Unfortunately, Flow can't make this sort of analysis, so we need to explicitly
        // ensure that `auxValues[i + 1]` is not null.
        if (nextFrom) {
          to = nextFrom - 1
        }
      }

      let prevRange = step.ranges.find((range) => {
        return range.from == from && range.to == to
      })
      if (prevRange) {
        ranges.push({...prevRange})
      } else {
        ranges.push({
          from: from,
          to: to,
          skipLogic: null
        })
      }
    }

    // be happy
    return {
      ...step,
      minValue: minValue,
      maxValue: maxValue,
      rangesDelimiters: rangesDelimiters,
      ranges: ranges
    }
  })
}

const changeRangeSkipLogic = (state, action) => {
  return changeStep(state, action.stepId, step => {
    let newRange = {
      ...step.ranges[action.rangeIndex],
      skipLogic: action.skipLogic
    }
    return {
      ...step,
      ranges: [
        ...step.ranges.slice(0, action.rangeIndex),
        newRange,
        ...step.ranges.slice(action.rangeIndex + 1)
      ]
    }
  })
}

const uploadCsvForTranslation = (state, action) => {
  // Convert CSV into a dictionary:
  // {defaultLanguageText -> {otherLanguage -> otherLanguageText}}
  const defaultLanguage = state.defaultLanguage
  const csv = action.csv

  // Replace language names with language codes
  const languageNames = csv[0]
  const languageCodes = languageNames.map(name => language.nameToCode(name))
  csv[0] = languageCodes

  const lookup = buildCsvLookup(csv, defaultLanguage)

  let newState = {...state}
  newState.steps = state.steps.map(step => translateStep(step, defaultLanguage, lookup))
  if (state.quotaCompletedMsg) {
    newState.quotaCompletedMsg = translatePrompt(state.quotaCompletedMsg, defaultLanguage, lookup)
  }
  if (state.errorMsg) {
    newState.errorMsg = translatePrompt(state.errorMsg, defaultLanguage, lookup)
  }
  return newState
}

const translateStep = (step, defaultLanguage, lookup): any => {
  let newStep = {...step}
  newStep.prompt = translatePrompt(step.prompt, defaultLanguage, lookup)
  if (step.type === 'multiple-choice') {
    newStep.choices = translateChoices(newStep.choices, defaultLanguage, lookup)
    return newStep
  }
  return newStep
}

const translatePrompt = (prompt, defaultLanguage, lookup) => {
  let defaultLanguagePrompt = prompt[defaultLanguage]
  if (!defaultLanguagePrompt) return prompt

  let newPrompt = {...prompt}
  let translations

  let sms = defaultLanguagePrompt.sms
  if (sms && (translations = lookup[sms])) {
    addTranslations(newPrompt, translations, 'sms')
  }

  let ivr = defaultLanguagePrompt.ivr
  if (ivr && ivr.audioSource == 'tts' && (translations = lookup[ivr.text])) {
    for (let lang in translations) {
      const text = translations[lang]
      if (!prompt[lang] || !prompt[lang].ivr || prompt[lang].ivr.audioSource == 'tts') {
        if (newPrompt[lang]) {
          newPrompt[lang] = {...newPrompt[lang]}
        } else {
          newPrompt[lang] = {}
        }
        newPrompt[lang].ivr = {text, audioSource: 'tts'}
      }
    }
  }

  return newPrompt
}

const addTranslations = (obj, translations, funcOrProperty) => {
  for (let lang in translations) {
    const text = translations[lang]
    if (obj[lang]) {
      obj[lang] = {...obj[lang]}
    } else {
      obj[lang] = {}
    }
    if (typeof (funcOrProperty) == 'function') {
      funcOrProperty(obj[lang], text)
    } else {
      obj[lang][funcOrProperty] = text
    }
  }
}

const translateChoices = (choices, defaultLanguage, lookup) => {
  return choices.map(choice => translateChoice(choice, defaultLanguage, lookup))
}

const translateChoice = (choice, defaultLanguage, lookup) => {
  let { responses } = choice
  if (!responses.sms || !responses.sms[defaultLanguage]) return choice

  let newChoice = {
    ...choice,
    responses: {...choice.responses}
  }

  const defLangResp = (responses.sms[defaultLanguage] || []).join(', ')

  newChoice.responses.sms = processTranslations(defLangResp, newChoice.responses.sms || {}, lookup)

  return newChoice
}

const processTranslations = (value, obj, lookup, funcOrProperty) => {
  let translations
  if (value && (translations = lookup[value])) {
    for (let lang in translations) {
      obj = {
        ...obj,
        [lang]: translations[lang].split(',').map(s => s.trim())
      }
    }
  }
  return obj
}

// Converts a CSV into a dictionary:
// {defaultLanguageText -> {otherLanguage -> otherLanguageText}}
const buildCsvLookup = (csv, defaultLanguage) => {
  const lookup = {}
  const headers = csv[0]
  const defaultLanguageIndex = headers.indexOf(defaultLanguage)

  for (let i = 1; i < csv.length; i++) {
    const row = csv[i]
    const defaultLanguageText = row[defaultLanguageIndex]
    if (!defaultLanguageText || defaultLanguageText.trim().length == 0) {
      continue
    }

    for (let j = 0; j < headers.length; j++) {
      if (j == defaultLanguageIndex) continue

      const otherLanguage = headers[j]
      const otherLanguageText = row[j]

      if (!otherLanguageText || otherLanguageText.trim().length == 0) {
        continue
      }

      if (!lookup[defaultLanguageText]) {
        lookup[defaultLanguageText] = {}
      }

      lookup[defaultLanguageText][otherLanguage] = otherLanguageText
    }
  }

  return lookup
}
