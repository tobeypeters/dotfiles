/*
    The MIT License(MIT)
    Copyright(c), Tobey Peters, https://github.com/tobeypeters
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software
    and associated documentation files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*  App.js
    Description:
        Unoffical Pokémon Pokédex.  This is a personal project. I don't plan on
        letting anyone else use it, except for family.
    Copyright Info:
        All property [ images & data ] belong and are registered trademarks and such, of the following companies:
          The Pokémon Company : Internation - http://www.pokemon.com
          Nintendo of America, Inc - http://www.nintendo.com
        NOTE: Data is being pulled from http://www.pokeapi.co
    Resources:
        Javascript library: npm install pokedex-promise-v2 --save
        Sprites:
          pokeApi provides sprites, but are lower quality. They are good, don't get me wrong.
          Official (Hi-Res) : https://assets.pokemon.com/assets/cms2/img/pokedex/full/001.png
                              https://assets.pokemon.com/assets/cms2/img/pokedex/detail/012.png
          https://cardmavin.com/media-category/pokemon-set-symbols
        Misc:
          https://stackoverflow.com/questions/26736209/how-do-i-stop-animation-in-html-and-css
          https://loading.io/css/
          https://www.tiktok.com/@thesnikle/video/7036799720718650670?is_from_webapp=1&sender_device=pc&web_id=7164190503155566126
*/

import { useEffect, useMemo, useState } from 'react';

// import { Items, Moves } from './components/Items';

import Logo from './Logo';
import PokemonList from './PokemonList';
import Spinner from './Spinner';

import { arrClear, fillPromises, fillPromises2, grabData, titleCase } from './utilities';

// import { MovesProvider } from './DataFarm';

import { DisplayMove } from './components/DisplayMove';

import { useMovesQuery } from './components/Moves';

const baseURL = 'https://pokeapi.co/api/v2/';

export {baseURL}

function App() {
  const [data, setData] = useState([]);

  // .... delete all your existing useEffect crap
  const movesBundles = useMovesQuery(1000);
  const movesList = movesBundles.map(bundle => {
    const {
      query: { queryKey: [{ moveName }] },
      bundle: {
        isLoading,
        isError,
        data,
        error
      },
    } = bundle;
    return (
      <>
      { console.log('here') }
      <li key={moveName}>
        {moveName}
        <DisplayMove
          isLoading={isLoading}
          isError={isError}
          data={data}
          error={error}
        />
      </li>
      </>
    );
  });

//   // const movetable = useMovesQuery(825);
//   // console.log('movetable',movetable);

//   useEffect(() => {

//     //Right now, only get data once
//     const getPokeData = async () => {
//       let promises = [];
//       let bufferA = [];

//       let response = await fetch(`${baseURL}pokemon-species?limit=5000`);
//       if (response.ok) {
//         let result = await response.json();

//         /*
//           abilities, base_experience
//           forms, game_indices
//           height, held_items
//           id, is_default
//           location_area_encounters, moves
//           name, order
//           past_types, species,
//           sprites, stats,
//           types,weight
//         */

//         fillPromises(promises,[`${baseURL}pokemon/`],result.results.length);
//         Promise.allSettled(promises)
//         .then(results => {
//           results.forEach(res => {
//             if (res.status === "fulfilled") {
//               const pokemon = Array(res.value).map(p => ({
//                 id: p.id,
//                 is_default: p.is_default,
//                 name: p.name,
//                 height: p.height,
//                 weight: p.weight,

//                 sprites: [
//                 [`${'https://assets.pokemon.com/assets/cms2/img/pokedex/full/'}${p.id.toString().padStart(3,'0')}.png`, 'Front Default'],
//                 // [p.sprites['front_default'], 'Front Default'],
//                 [p.sprites['back_default'], 'Back Default' ],
//                 [p.sprites['front_shiny'], 'Front Shiny' ],
//                 [p.sprites['back_shiny'], 'Back Shiny' ],

//                 /*
//                 [p.sprites['front_female'], 'Front Female' ],
//                 [p.sprites['back_female'], 'Back Female' ],
//                 [p.sprites['front_shiny_female'], 'Front Shiny Female' ],
//                 [p.sprites['back_shiny_female'], 'Back Shiny Female' ],
//                 */
//                 ],

//                 abilities: p.abilities
//                           .filter(a => !a.is_hidden)
//                           .map(a => a.ability.name).join(', '),
//                 abilities2: [ p.abilities
//                           .filter(a => !a.is_hidden)
//                           .map(a => a.ability.name) ][0],

//                 base_experience: p.base_experience,
//                 forms: p.forms[0],
//                 game_indices: p.game_indices,
//                 held_items: [ p.held_items.map(a => a.item.name) ][0],
//                 types: p.types.map((type) => type.type.name).join(', '),
//                 types2: [ p.types.map((type) => type.type.name) ][0],
//                 location_area_encounters: p.location_area_encounters,
//                 moves: p.moves,
//                 moveArr: [],
//                 order: p.order,
//                 past_types: p.past_types,
//                 species: p.species,
//                 stats: p.stats,
//               }));

//               bufferA.push(pokemon[0]);
//             } // if
//           }); // forEach
//           console.log('one');
//         }) // then main
//         .then (res => {
//           console.log('two');
//           fillPromises(promises,[`${baseURL}pokemon-form/`],result.results.length);
//           return Promise.allSettled(promises)
//           .then (results => {
//             results.forEach(res => {
//               if (res.status === "fulfilled") {
//                 bufferA[res.value.id - 1].formName =
//                 titleCase(res.value.version_group.name.replace('-', ' & '));
//               }
//             });
//           }) // then results
//         }) // then formName
//         .then (res => {
// console.log('three');
//           setData(bufferA);
//           arrClear(promises);
//         })
//       } // response.ok

//     }; //getPokeData
//     getPokeData();

//   },[]); //useEffect

  return (
    //Items(`${baseURL}move?limit=5000`);
    <div className="App">
      <ul>{movesList}</ul>
    {/* <MovesProvider> */}
      {/* { data.length ? <Moves /> : (<></>) }
      <Logo />
      <br />
      <div >
        { data.length ? <PokemonList pokemon={data}/> :
          <Spinner /> }
      </div> */}
    {/* </MovesProvider> */}
    </div>
 )

}

export default App;