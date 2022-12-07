import React from 'react'

export function DisplayMove({isLoading,isError,data,error}) {
  return (
    <div>
        {/* Just display all the parameters to see what we get. */}
        <span>{data}</span>
        <span>{isLoading}</span>
        <span>{isError}</span>
        <span>{isError}</span>
    </div>
  )
}