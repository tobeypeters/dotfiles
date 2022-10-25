import React from 'react'

import styles from './App.module.css'

/* Resources:
   https://textcraft.net/style/Textcraft/pokemon
*/
export default function Logo() {
  return (
    <div className={styles.logo}>
      <img src={process.env.PUBLIC_URL + 'images/benjemonlogo.png'} alt='logo'/>
    </div>
  )
}
