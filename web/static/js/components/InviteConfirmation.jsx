import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../actions/invites'
import * as routes from '../routes'

class InviteConfirmation extends Component {
  componentDidMount() {
    const code = this.props.location.query.code
    this.props.actions.fetchInvite(code)
  }

  confirmInvitation() {
    const code = this.props.location.query.code
    Promise.resolve(this.props.actions.confirm(code)).then(() => {
      window.location = routes.projects
    })
  }

  render() {
    return (
      <div>
        <div> You have been invited to collaborate in project </div>
        <a onClick={() => this.confirmInvitation()}> ACCEPT INVITATION </a>
      </div>
    )
  }
}

InviteConfirmation.propTypes = {
  location: PropTypes.object.isRequired,
  actions: PropTypes.object.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(InviteConfirmation)