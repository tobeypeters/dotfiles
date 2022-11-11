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

import { lowerCase, titleCase } from './utilities';

function App() {
  const baseURL = 'https://pokeapi.co/api/v2/';
  //const pokeURL = `${baseURL}pokemon-species?limit=5000`;

  const [data, setData] = useState([]);
  const [moves, setMoves] = useState([]);

  useEffect(() => {
    //Right now, only get data once
    const getPokeData = async () => {
      let promises = [];
      let bufferA = [];

      const fillPromises = (buffer , url = [], count = 0) => {
        console.log(`url : ${url}`);
        const singleURL = url.length === 1;

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
      }

      const getData = await fetch(`${baseURL}move?limit=5000`)
                     .then(async res => res.status === 200 ? await res.json() : null)
                     .then(res => {

                      let fdx = 0;
                      res.results.forEach((el, idx) => {
                        if (el.url.includes('10001')) fdx = idx;
                      })
                      res.results.splice(fdx,res.results.length);

                        // fillPromises(promises,[`${baseURL}move/`],res.results.length)
                        // Promise.allSettled(promises)
                        // .then(res => {
                        //   res.forEach(res => {
                        //     if (res.status === 'fulfilled') {
                        //       const move = Array(res.value).map(p => ({
                        //         name: p.name,
                        //       }));

                        //       //console.log(move);
                        //       bufferA.push(move);
                        //     }
                        //   })
                        // })
                        // promises.slice(0,promises.length);
                        // promises = [];
                     });

      //console.log(bufferA);
      bufferA.splice(0, bufferA.length);
      bufferA = [];

      //console.log(getData.results);

      let response = await fetch(`${baseURL}pokemon-species?limit=5000`);
      if (response.ok) {
        let result = await response.json();

/*  abilities, base_experience
    forms, game_indices
    height, held_items
    id, is_default
    location_area_encounters, moves
    name, order
    past_types, species,
    sprites, stats,
    types,weight
*/

//        fillPromises(promises,['https://pokeapi.co/api/v2/pokemon/'],result.results.length);
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
          }) // then
          .then (res => {
            promises.splice(0, promises.length);
            promises = [];

            // console.log(`bufferA : ${bufferA[5][0].name}`);

            fillPromises(promises,[`${baseURL}pokemon-form/`],result.results.length);
            Promise.allSettled(promises)
            .then (results => {
              //console.log(`here : ${bufferA}`);
              results.forEach(res => {
                if (res.status === "fulfilled") {
                  bufferA[res.value.id - 1][0].formName =
                  titleCase(res.value.version_group.name.replace('-', ' & '));
                }
              });
              return results;
            })
            })
            .then (() => {
              // promises.splice(0, promises.length);
              // promises = [];

              //console.log(bufferA);

              // let lookupURL = [];

              console.log('bufferA test start ------------------')
              console.log(bufferA[0][0]);
              bufferA.forEach(f => {
                if (f[0].id === 1) {
                  console.log(f[0].name);
                  console.log(f[0].formName);
                }

              console.log('bufferA test end ------------------')


                //const lookupVG = lowerCase(f[0].formName).replace(' & ', '-');
                //console.log(f);

                // lookupURL.splice(0,lookupURL.length);
                // lookupURL = [];

                //console.log(f[0]);

                //f[0].moves.forEach(ff => {
              //     ff.version_group_details.forEach(fff => {
              //       if ((fff.level_learned_at === 0) &&
              //           (fff.version_group.name === lookupVG))
              //         lookupURL.push(fff.version_group.url);
              //       });
                //}); // moves.forEach
              }); // bufferA.forEach
            }) // res then
            .then (() => setData(bufferA))

            // bufferA.splice(0, bufferA.length);
            // promises.splice(0, promises.length);
          // }) // form then

      } // response.ok

}; //getData
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