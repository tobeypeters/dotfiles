import React from 'react'

import styles from './App.module.css'

/*
const pokemon = Array(res.value).map(p => ({
  id: p.id,
  is_default: p.is_default,
  name: p.name,
  height: p.height,
  weight: p.weight,

  sprites: [
    [p.sprites['front_default'], 'Front Default'],
    [p.sprites['back_default'], 'Back Default' ],
    [p.sprites['front_shiny'], 'Front Shiny' ],
    [p.sprites['back_shiny'], 'Back Shiny' ],
    [p.sprites['front_female'], 'Front Female' ],
    [p.sprites['back_female'], 'Back Female' ],
    [p.sprites['front_shiny_female'], 'Front Shiny Female' ],
    [p.sprites['back_shiny_female'], 'Back Shiny Female' ],
  ],

  abilities: p.abilities,
  base_experience: p.base_experience,
  forms: p.forms,
  game_indices: p.game_indices,
  held_items: p.held_items,
  types: p.types.map((type) => type.type.name).join(', '),
  location_area_encounters: p.location_area_encounters,
  moves: p.moves,
  order: p.order,
  past_types: p.past_types,
  species: p.species,
  stats: p.stats,
}));
*/

/* https://codepen.io/FlorinPop17/pen/gOYZxyE */
const colors = {
  fire: '#FDDFDF',
  grass: '#DEFDE0',
  electric: '#FCF7DE',
  water: '#DEF3FD',
  ground: '#f4e7da',
  rock: '#d5d5d4',
  fairy: '#fceaff',
  poison: '#98d7a5',
  bug: '#f8d5a3',
  dragon: '#97b3e6',
  psychic: '#eaeda1',
  flying: '#F5F5F5',
  fighting: '#E6E0D4',
  normal: '#F5F5F5'
};

export default function PokeCard({pokechar}) {
  const el = pokechar[0];

  const cardID = 'card_' + el.name;
  const cardImageID = 'cardImage_' + el.name;
  const cardNameID = 'cardName_' + el.name;
  const cardInfoID = 'cardInfo_' + el.name;

  const charTypes = el.types.split(', ');

  const minImagePX = '20px';
  const maxImagePX = '180px';

  const getElm = eID => document.getElementById(eID);

/*   test.forEach(element => {
    console.log(element);
    element.style.display = 'none';
  });
 */

  const imageClick = () => {
    const elm = getElm(cardImageID);

    let idx = parseInt(elm.alt);

    idx = idx + (idx < 3 ? 1 : -idx);
    elm.alt = idx;
    elm.src = el.sprites[idx][0];
    elm.title = el.sprites[idx][1];
  }

  const showPokeDetail = function (ev) {
/*     const test = Array.from(
      document.getElementsByClassName(styles.pokeName)
    );
 */
    const elm = getElm(cardImageID);
    const elmName = getElm(cardNameID);
    const elmInfo = getElm(cardInfoID);

    if (ev.target instanceof HTMLDivElement ||
        ev.target.id === cardNameID ) {

      if ((elm.clientHeight+'px') === maxImagePX) {
        elm.style.height = minImagePX;
        elm.style.objectFit = 'contain';
        elmName.style.display = 'none';
        elmInfo.style.display = 'block';
      } else {
        elm.style.height = maxImagePX;
        elm.style.objectFit = 'fill';
        elmName.style.display = 'block';
        elmInfo.style.display = 'none';
      }
    }
  }

  return (
    <>
      <div id={cardID} className={styles.card} key={el.name} style={{background: colors[charTypes[0]] }}
       onClick={ showPokeDetail } >
        <img id={cardImageID} className={styles.cardimage} src={el.sprites[0][0]} alt='0'
         onClick={ imageClick } title={el.sprites[0][1]} />

        <span id={cardNameID} className={styles.pokeName} title='Click here for more detail...' >#{el.id.toString().padStart(3,'0')}&nbsp;:&nbsp;
        {el.name.charAt(0).toUpperCase() + el.name.slice(1)}
        </span>

        <div id={cardInfoID} className={styles.pokeInfo} >
        <br />Weight: {el.weight/10}kg
        <br />Height: {el.height/10}m
        <br />Base Experience: {el.base_experience}
        <br />{el.types}
        </div>

      </div>
    </>
  )
}