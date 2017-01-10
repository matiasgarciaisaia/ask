import React, { Component, PropTypes } from 'react'
import uuid from 'node-uuid'
import classNames from 'classnames/bind'

export class Modal extends Component {
  componentDidMount() {
    $(this.refs.modal).modal()
  }

  render() {
    const { showLink, linkText, style, children, card = false } = this.props
    const id = this.props.id || uuid.v4()

    let modalLink = null
    if (showLink) {
      modalLink = (<a className='modal-trigger' href={`#${id}`}>{linkText}</a>)
    }

    return (
      <div>
        {modalLink}
        <div id={id} className={classNames({'modal': true, 'card': card})} style={style} ref='modal'>
          {children}
        </div>
      </div>
    )
  }
}

Modal.propTypes = {
  showLink: PropTypes.bool,
  card: PropTypes.bool,
  children: PropTypes.node,
  linkText: PropTypes.string,
  id: PropTypes.string.isRequired,
  style: PropTypes.object
}