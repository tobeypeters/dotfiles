import React from 'react'

// export function DisplayMove({isLoading,isError,data,error}) {
export function DisplayMove(props) {
    return (
    <div>
        {/* Just display all the parameters to see what we get. */}
        <span>{props.data} </span>
        <span>{props.isLoading} </span>
        <span>{props.isError} </span>
        <span>{props.isError} </span>
    </div>
  )
}