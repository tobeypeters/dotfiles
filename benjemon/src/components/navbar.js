import { NavLink } from 'react-router-dom';

import { titlecase } from '../utility';

import styles from '../App.module.css';

import pball from '../assets/pball.png';

import { useState } from 'react';

import { Fragment } from 'react';

export function Navbar(props) {
  const [angle,setAngle] = useState(0);
  const [isVisible, setIsVisible] = useState(true);
  const [flipped, setFlipped] = useState(false);

  const handleClick = () => {
    setAngle(prevAngle => (prevAngle === 0 ? -90 : 0));
    setIsVisible(!isVisible);
//    setMenu((prevMenu) => (prevMenu + 90) % 360);
  };

  const displocation = (loc,disp) =>
    props.location === loc ? false : titlecase(disp.replace('/',''));

  const sep = '>';

  const urls = ['/home','/characters','/moves','/items'];

  const active = props.location === '/' ? 'Home' :
                 titlecase(props.location.replace('/',''));

  const buildbar = () => {
    let bar = urls.map((m, idx) => {
      let displink = displocation(m,m);

      /*This is a little janky, on how it works. We don't want to
        display the page we're on or the extra seperator(s) hiding
        an item creates.

              loc: '/home'  menu:  Characters > Moves > Items
        loc: '/characters'  menu:  Home > Moves > Items
      */
      let skip =
        idx === 0 || (idx === 1 && props.location === urls[0] )
                  || !Boolean(displink);

      return (
        <Fragment key={idx}>
          {skip ? '': <span className={styles.navsep}>&nbsp;{sep}&nbsp;</span>}
          <NavLink key={m} to={m}>{displink}</NavLink>
        </Fragment>
      )
    })

    return bar;
  }

  return (
    <>
      <div className={styles.navbar}>
        <img style={{transition: `transform .50s`,
                     transform: `rotate(${angle}deg)`}}
             className={styles.navbutton} src={pball}
             alt='pokeball' onClick={handleClick}
             title={angle === 0 ? `Hide Menu` : `Show Menu`} />
        <div className={styles.navlinks}>
          {isVisible ?  buildbar() : ``}
        </div>
        <div className={styles.navactivetitle}>{active} - Benjémon</div>
        <div className={styles.navinfo}></div>
      </div>

    </>
  );
};
