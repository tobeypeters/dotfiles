import { NavLink } from "react-router-dom";

import { titlecase } from "../utility";

import styles from "../App.module.css";

export function Navbar(props) {
  const displocation = (loc,disp) =>
    props.location === loc ? false : titlecase(disp.replace('/',''));

  const sep = ' > ';

  const urls = ['/home','/characters','/moves','/items'];

  const buildbar = () => {
    let bar = urls.map((m, idx) => {
      let displaystring = displocation(m,m);

      /*This is a little janky, on how it works. We don't want to
        display the page we're on or the extra seperator(s) hiding
        an item creates.

              loc: '/home'  menu:  Characters > Moves > Items
        loc: '/characters'  menu:  Home > Moves > Items
      */
      let skip =
        idx === 0 || (idx === 1 && props.location === '/home' )
                  || !Boolean(displaystring);

      return (
        <>
          {skip ? '': <span className={styles.navsep}>{sep}</span>}
          <NavLink key={idx} to={m}>{displaystring}</NavLink>
        </>
      )
    })

    return bar;
  }

  return (
    <>
      <div className={styles.navbar}>
        <div className={styles.navbutton}></div>
          <div className={styles.navlinks}>
            {buildbar()}
          </div>
      </div>
    </>
  );
};
