import { NavLink } from "react-router-dom";

import { titlecase } from "../utility";

import styles from "../App.module.css";

export function Navbar(props) {
  const displocation = (loc,disp) =>
        props.location === loc ? '' : titlecase(disp.replace('/',''));

  const sep = ' > ';

  const urls = ['/home','/characters','/moves','/items'];
        // <>
        //   {prevdisp ? sep : ''}
        //   {/* {displaystring && idx > 0 ? sep : ''} */}
        //   <NavLink key={idx} to={m}>{displaystring}</NavLink>
        //   {prevdisp = Boolean(displaystring) && idx < urls.length - 1}

  const buildbar = () => {
    let prevdisp = false;
    let bar = urls.map((m, idx) => {
      let displaystring = displocation(m,m);
      let last = idx === urls.length - 1;

      return (
        <>
        {last ? ' gato ' : <>
          {prevdisp ? sep : ''}
          {/* {displaystring && idx > 0 ? sep : ''} */}
          <NavLink key={idx} to={m}>{displaystring}</NavLink>
          {prevdisp = Boolean(displaystring) && idx < urls.length - 1}
        </>
      }
        </>
      )
    })

    if (bar[bar.length - 1].props.children[0].includes(sep)) {
      bar[bar.length - 1].props.children[0].replace(sep,'');
      // bar[bar.length - 2].props.children[0].replace(sep,'');

      console.log('gato',bar[bar.length - 1].props.children[0]);
    }

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
