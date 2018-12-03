import * as actions from '../../actions/ui'

const initialState = {
  uploadingAudio: null,
  steps: {
    currentStepId: null,
    currentStepIsNew: false
  },
  quotaCompletedSteps: {
    currentStepId: null,
    currentStepIsNew: false
  },
  importingQuestionnaire: false,
  importPercentage: 0
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.UPLOAD_AUDIO: return uploadingAudio(state, action)
    case actions.FINISH_AUDIO_UPLOAD: return finishAudioUpload(state, action)
    case actions.IMPORT_QUESTIONNAIRE: return importingQuestionnaire(state, action)
    case actions.UPDATE_IMPORT_PERCENTAGE: return updateImportPercentage(state, action)
    case actions.FINISH_QUESTIONNAIRE_IMPORT: return finishQuestionnaireImport(state, action)
    case actions.QUESTIONNAIRE_SELECT_QUOTA_COMPLETED_STEP: return selectQuotaCompletedStep(state, action)
    case actions.QUESTIONNAIRE_DESELECT_QUOTA_COMPLETED_STEP: return deselectQuotaCompletedStep(state, action)
    case actions.QUESTIONNAIRE_SELECT_STEP: return selectStep(state, action)
    case actions.QUESTIONNAIRE_DESELECT_STEP: return deselectStep(state, action)
    default: return state
  }
}

const uploadingAudio = (state, action) => {
  return {
    ...state,
    uploadingAudio: action.stepId
  }
}

const finishAudioUpload = (state, action) => {
  return {
    ...state,
    uploadingAudio: null
  }
}

const importingQuestionnaire = (state, action) => {
  return {
    ...state,
    importingQuestionnaire: true
  }
}

const updateImportPercentage = (state, action) => {
  return {
    ...state,
    importPercentage: action.importPercentage
  }
}

const finishQuestionnaireImport = (state, action) => {
  return {
    ...state,
    importingQuestionnaire: false
  }
}

const selectStep = (state, action) => {
  return {
    ...state,
    steps: {
      currentStepId: action.stepId,
      currentStepIsNew: action.isNew
    }
  }
}

const selectQuotaCompletedStep = (state, action) => {
  return {
    ...state,
    quotaCompletedSteps: {
      currentStepId: action.stepId,
      currentStepIsNew: action.isNew
    }
  }
}

const deselectStep = (state, action) => {
  return {
    ...state,
    steps: {
      currentStepId: null,
      currentStepIsNew: false
    }
  }
}

const deselectQuotaCompletedStep = (state, action) => {
  return {
    ...state,
    quotaCompletedSteps: {
      currentStepId: null,
      currentStepIsNew: false
    }
  }
}
