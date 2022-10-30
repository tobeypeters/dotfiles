import React from 'react'

import styles from './App.module.css'

import placeholder from './assets/Placeholder.png'

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

const colors = {
  bug: '#83a751',
  dragon: '#97b3e6',
  dark: '#36454f',
  electric: '#f2d57a',
  fairy: '#fceaff',
  fighting: '#e6e0d4',
  fire: '#dd563b',
  flying: '#f5f5f5',
  ghost: '#f8f8ff',
  grass: '#5f8473',
  ground: '#c9b2a2',
  ice: '#fcfbfc',
  normal: '#f5f5f5',
  poison: '#885f7e',
  psychic: '#eaeda1',
  rock: '#55524e',
  steel: '#708090',
  water: '#8ec3cf'
};

export default function PokeCard({pokechar}) {
  const el = pokechar[0];

  if (el.sprites[1][0] === null) { // Validate images
  //   el.sprites[0][0] = `https://assets.pokemon.com/assets/cms2/img/pokedex/full/${el.id.toString().padStart(3,'0')}.png`;
     el.sprites[1][0] = placeholder;
     el.sprites[2][0] = placeholder;
     el.sprites[3][0] = placeholder;
  }

  const cardID = 'card_' + el.name;
  const cardImageID = 'cardImage_' + el.name;
  const cardMiniImageID = 'cardMiniImage_' + el.name;
  const cardNameID = 'cardName_' + el.name;
  const cardInfoID = 'cardInfo_' + el.name;

  const charTypes = el.types.split(', ');

  const charBG = `linear-gradient(${colors[charTypes[0]]},lightgrey)`;
  const charTypeBG = `linear-gradient(90deg,${colors[charTypes[0]]},lightgrey,${charTypes.length === 1 ? colors[charTypes[0]]:colors[charTypes[1]]})`;

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
      <div id={cardID} className={styles.card} key={el.name} style={{ backgroundImage: charBG }}
      onClick={ showPokeDetail } >
        <img id={cardImageID} className={styles.cardimage} loading='lazy' src={el.sprites[0][0]} alt='0'
         onClick={ imageClick } title={el.sprites[0][1]} />

        <span id={cardNameID} className={styles.pokeName} title='Click here for more detail...' >
        <img id={cardMiniImageID} className={styles.cardMiniImage} loading='lazy' src={el.sprites[0][0]} alt='0' />
          {/* #{el.id.toString().padStart(3,'0')}&nbsp;:&nbsp; */}
        {el.name.charAt(0).toUpperCase() + el.name.slice(1)}
        </span>

        <div id={cardInfoID} className={styles.pokeInfo} >
        Weight: {el.weight/10}kg
        <br />Height: {el.height/10}m
        <br />{el.base_experience}XP
        <br />{el.abilities}
        <br />{el.is_default}
        <br />{el.order}
        <br />Types: <span style={{ backgroundImage: charTypeBG, padding: '0px 10px 0px 10px' }}>{el.types}</span>

        </div>

      </div>
    </>
  )
}