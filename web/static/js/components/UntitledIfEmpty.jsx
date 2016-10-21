import React, { PropTypes } from 'react'

const UntitledIfEmpty = ({ text, emptyText = 'Untitled' }) => {
  if (!text || text.trim() === '') {
    return <em>{emptyText}</em>
  } else {
    return <span>{text}</span>
  }
}

UntitledIfEmpty.propTypes = {
  text: PropTypes.string,
  emptyText: PropTypes.string
}

export default UntitledIfEmpty
