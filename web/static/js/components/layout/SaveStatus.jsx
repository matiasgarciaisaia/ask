import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import TimeAgo from 'react-timeago'
import { withRouter } from 'react-router'

import { translate } from 'react-i18next'

class SaveStatus extends Component {

  formatter(number, unit, suffix, date, defaultFormatter) {
    const { t } = this.props

    if (unit == 'second') {
      return t('All changes saved')
    }

    switch (unit) {
      case 'minute':
        return t(`Last saved {{count}} minute ago`, {count: number})
      case 'hour':
        return t(`Last saved {{count}} hour ago`, {count: number})
      case 'day':
        return t(`Last saved {{count}} day ago`, {count: number})
      case 'week':
        return t(`Last saved {{count}} week ago`, {count: number})
      case 'month':
        return t(`Last saved {{count}} month ago`, {count: number})
      case 'year':
        return t(`Last saved {{count}} year ago`, {count: number})
      default:
        return t(`Last saved {{count}} ${unit} {{text}}`, {count: number, text: suffix})
    }
  }

  render() {
    const { saveStatus, routes, t } = this.props

    let show = false

    const bindedFormatter = this.formatter.bind(this)

    for (var i = routes.length - 1; i >= 0; i--) {
      if (routes[i].showSavingStatus) {
        show = true
        break
      }
    }

    if (show && saveStatus && (saveStatus.saving || saveStatus.updatedAt)) {
      if (saveStatus.saving) {
        return (
          <div className='right grey-text'>{t('Saving...')}</div>
        )
      } else {
        return (
          <div className='right grey-text'><TimeAgo minPeriod='60' date={saveStatus.updatedAt + '+0000'} formatter={bindedFormatter} /></div>
        )
      }
    } else {
      return (<div />)
    }
  }
}

SaveStatus.propTypes = {
  saveStatus: PropTypes.any,
  t: PropTypes.func,
  routes: PropTypes.any
}

const mapStateToProps = (state, ownProps) => ({
  saveStatus: state.saveStatus || {}
})

export default translate()(withRouter(connect(mapStateToProps)(SaveStatus)))
