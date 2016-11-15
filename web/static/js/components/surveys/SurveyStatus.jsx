import React, { PureComponent } from 'react'
import RespondentsChart from '../respondents/RespondentsChart'
import * as RespondentsChartCount from '../respondents/RespondentsChartCount'
import * as routes from '../../routes'

export default class SurveyStatus extends PureComponent {
  static propTypes = {
    survey: React.PropTypes.object.isRequired
  }

  render() {
    const { survey } = this.props
    let cumulativeCount = []
    let reached = 0

    if (!survey) {
      return <p>Loading...</p>
    }

    let icon = 'mode_edit'
    let color = 'black-text'
    let text = 'Editing'
    switch (survey.state) {
      case 'running':
        icon = 'play_arrow'
        color = 'green-text'
        text = 'Running'
        break
      case 'ready':
        icon = 'play_circle_outline'
        color = 'black-text'
        text = 'Ready to launch'
        break
      case 'completed':
        icon = 'done'
        color = 'black-text'
        text = 'Completed'
        break
    }
    return (
      <p className={color}>
        <i className='material-icons survey-status'>{icon}</i>
        { text }
      </p>
    )
  }
}