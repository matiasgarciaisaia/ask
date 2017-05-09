// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class ExplanationStep extends Component {
  getValue() {
    return ''
  }

  clearValue() {}

  render() {
    const { step, progress } = this.props

    let nextButton = null
    if (progress != 100) {
      nextButton = (
        <button className='btn large block'>
          <svg height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'>
            <path d='M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z' />
          </svg>
        </button>
      )
    }

    return (
      <div>
        {(step.prompts || []).map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
        {nextButton}
      </div>
    )
  }
}

ExplanationStep.propTypes = {
  step: PropTypes.object,
  progress: PropTypes.number
}

export default ExplanationStep
