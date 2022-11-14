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

import { useEffect, useState } from 'react';

import Logo from './Logo';
import PokemonList from './PokemonList';
import Spinner from './Spinner';

import { cleanse, lowerCase, titleCase } from './utilities';

function App() {
  const baseURL = 'https://pokeapi.co/api/v2/';
  //const pokeURL = `${baseURL}pokemon-species?limit=5000`;

  const [data, setData] = useState([]);
  const [dataMoves, setDataMoves] = useState([]);

  var bufferA = [];

  useEffect(() => {
    //Right now, only get data once
    const getPokeData = async () => {
      let promises = [];

      const fillPromises = (buffer , url = [], count = 0) => {
        const singleURL = url.length === 1;

        cleanse(buffer);

        for (let i = 1; i <= count; i++) {
          const fetchPUSH = singleURL ? `${url[0]}${i}` : url[i - 1];
          buffer.push(
            fetch(fetchPUSH)
              .catch(err => { console.log(`buffer.push().catch err : ${err}`) })
              .then(res => {
                return res.status === 200 ? res.json() : null;
              })
          )
        }
      };

      const buildMoveLookup = async () => {
console.log('four');
        let fdx = 0;
        await fetch(`${baseURL}move?limit=5000`)
        .then(async res => res.status === 200 ? await res.json() : null)
        .then(res => {
          res.results.forEach((el, idx) => {
            if (el.url.includes('10001')) fdx = idx;
          })
        })

//         fillPromises(promises,[`${baseURL}move/`],fdx);
//         Promise.allSettled(promises)
//         .then(res => {
//           let bufferMove = [];
//           res.forEach(res => {
//             if (res.status === 'fulfilled') {
//               const move = Array(res.value).map(p => ({
//                 name: p.name,
//               }));

//               bufferMove.push(move);
//             }
//           })
// //          console.log(`bufferMove: ${bufferMove}`);
//           setDataMoves(bufferMove);
//           cleanse(bufferMove);
//         });
      }

      let response = await fetch(`${baseURL}pokemon-species?limit=5000`);
      if (response.ok) {
        let result = await response.json();

        /*
          abilities, base_experience
          forms, game_indices
          height, held_items
          id, is_default
          location_area_encounters, moves
          name, order
          past_types, species,
          sprites, stats,
          types,weight
        */

        fillPromises(promises,[`${baseURL}pokemon/`],result.results.length);
        Promise.allSettled(promises)
        .then(results => {
          results.forEach(res => {
            if (res.status === "fulfilled") {
              const pokemon = Array(res.value).map(p => ({
                id: p.id,
                is_default: p.is_default,
                name: p.name,
                height: p.height,
                weight: p.weight,

                sprites: [
                [`${'https://assets.pokemon.com/assets/cms2/img/pokedex/full/'}${p.id.toString().padStart(3,'0')}.png`, 'Front Default'],
                // [p.sprites['front_default'], 'Front Default'],
                [p.sprites['back_default'], 'Back Default' ],
                [p.sprites['front_shiny'], 'Front Shiny' ],
                [p.sprites['back_shiny'], 'Back Shiny' ],

                /*
                [p.sprites['front_female'], 'Front Female' ],
                [p.sprites['back_female'], 'Back Female' ],
                [p.sprites['front_shiny_female'], 'Front Shiny Female' ],
                [p.sprites['back_shiny_female'], 'Back Shiny Female' ],
                */
                ],

                abilities: p.abilities
                          .filter(a => !a.is_hidden)
                          .map(a => a.ability.name).join(', '),

                base_experience: p.base_experience,
                forms: p.forms,
                game_indices: p.game_indices,
                held_items: p.held_items,
                types: p.types.map((type) => type.type.name).join(', '),
                location_area_encounters: p.location_area_encounters,
                moves: p.moves,
                moveArr: [],
                order: p.order,
                past_types: p.past_types,
                species: p.species,
                stats: p.stats,
              }));

              bufferA.push(pokemon);
            } // if
          }); // forEach
          console.log('one');
        }) // then main
        .then (res => {
          console.log('two');
          fillPromises(promises,[`${baseURL}pokemon-form/`],result.results.length);
          return Promise.allSettled(promises)
          .then (results => {
            results.forEach(res => {
              if (res.status === "fulfilled") {
                bufferA[res.value.id - 1][0].formName =
                titleCase(res.value.version_group.name.replace('-', ' & '));
              }
            });
          }) // then results
        }) // then formName
        .then (() => {
console.log('three');
          setData(bufferA);

          cleanse(bufferA);
          cleanse(promises);

          buildMoveLookup();
        })
      } // response.ok

    }; //getPokeData
    getPokeData();
  },[]); //useEffect

  return (
    <div className="App">
      <Logo />
      <br />

      <div>
        {data.length ? (
          <PokemonList pokemon={data}/>
        ) : (
          <Spinner />)}
      </div>
    </div> // App
 )

}

export default App;