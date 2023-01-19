import { NavLink } from "react-router-dom";

import styles from "../App.module.css";

export function Navbar(props) {
  const sep = ' > ';

  return (
    <>
      <div className={styles.navbar}>
        <div className={styles.navbutton}></div>
        <div className={styles.navlinks}>
          <NavLink to='/home'>Home</NavLink>{sep}
          <NavLink to='/characters'>Characters</NavLink>{sep}
          <NavLink to='/moves'>Moves</NavLink>{sep}
          <NavLink to='/items'>Items</NavLink>
        </div>
      </div>
    </>
  );
};
