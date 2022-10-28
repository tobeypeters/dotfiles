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

  console.log(el.forms)

  const cardID = 'card_' + el.name;
  const cardImageID = 'cardImage_' + el.name;
  const cardMiniImageID = 'cardMiniImage_' + el.name;
  const cardNameID = 'cardName_' + el.name;
  const cardInfoID = 'cardInfo_' + el.name;

  const charTypes = el.types.split(', ');

  const getElm = eID => document.getElementById(eID);

  const imageClick = () => {
    const elm = getElm(cardImageID);

    let idx = parseInt(elm.alt);

    idx = idx + (idx < 3 ? 1 : -idx);

    elm.alt = idx;
    elm.src = el.sprites[idx][0];
    elm.title = el.sprites[idx][1];
  }

  const showPokeDetail = function (ev) {
    const elImgLarge = getElm(cardImageID);
    const elImgMini = getElm(cardMiniImageID);
    const elInfo = getElm(cardInfoID);

    if (ev.target instanceof HTMLDivElement ||
      ev.target.id === cardNameID ) {

      if (window.getComputedStyle(elImgLarge).display === 'block') {
        elImgLarge.style.display = 'none';
        elInfo.style.display = 'block';
        elImgMini.style.display = 'block';
      } else {
        elImgLarge.style.display = 'block';
        elInfo.style.display = 'none';
        elImgMini.style.display = 'none';
      }
    }

  }

  return (
    <>
      <div id={cardID} className={styles.card} key={el.name} style={{background: colors[charTypes[0]] }}
       onClick={ showPokeDetail } >
        <img id={cardImageID} className={styles.cardimage} src={el.sprites[0][0]} alt='0'
         onClick={ imageClick } title={el.sprites[0][1]} />

        <span id={cardNameID} className={styles.pokeName} title='Click here for more detail...' >
        <img id={cardMiniImageID} className={styles.cardMiniImage} src={el.sprites[0][0]} alt='0' />
          {/* #{el.id.toString().padStart(3,'0')}&nbsp;:&nbsp; */}
        {el.name.charAt(0).toUpperCase() + el.name.slice(1)}
        </span>

        <div id={cardInfoID} className={styles.pokeInfo} >
        Weight: {el.weight/10}kg
        <br />Height: {el.height/10}m
        <br />{el.base_experience}XP
        <br />{el.types}
        <br />{el.abilities}
        <br />{el.is_default}
        <br />{el.order}

        </div>

      </div>
    </>
  )
}