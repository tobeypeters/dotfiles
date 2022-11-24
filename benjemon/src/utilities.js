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

/*  utilities.js
    Description:
        miscellaneous utility functions
*/
import { useEffect, useRef } from "react";

const cleanse = (arr) => {
  if (Array.isArray(arr)) {
      arr.splice(0, arr.length);
  }
}

const grabData = async (url) => {
  let response = await fetch(url);
  let results = response.status === 200 ? await response.json() : null
  console.log(results.results);
  return results.results;
}

const block_Promises = async (buffer, url = [], count = 0, buffer_clear = true) => {
  const fillerUp = async (buffer , url = [], count = 0) => {
    const singleURL = url.length === 1;

    for (let i = 1; i <= count; i++) {
      const fetchPUSH = singleURL ? `${url[0]}${i}` : url[i - 1];
      buffer.push(
        await fetch(fetchPUSH)
        .catch(err => { console.log(`buffer.push().catch err : ${err}`) })
        .then(res => {
            return res.status === 200 ? res.json() : null;
          })
      )
    }
  };

  const MAX_GRAB_COUNT = 250;

  let grabHowMany = count <= MAX_GRAB_COUNT ? count : MAX_GRAB_COUNT;
  count -= grabHowMany;

  if (buffer_clear) cleanse(buffer);

  let arrIDX = 0;

  if (grabHowMany > 0) {
    do {
      await fillerUp(buffer,url.slice(arrIDX, arrIDX + grabHowMany),grabHowMany);

      arrIDX += grabHowMany;

      grabHowMany = count <= MAX_GRAB_COUNT ? count : MAX_GRAB_COUNT;
      count -= grabHowMany;
    } while (grabHowMany > 0);
  }

  console.log(buffer);
}

const fillPromises2 = async (buffer , url = [], count = 0, buffer_clear = true) => {
  const fillerUp = async (buffer , url = [], count = 0) => {
    const singleURL = url.length === 1;

    console.log(singleURL);
    console.log(url[0]);
    console.log(`count: ${count}`);
    for (let i = 1; i <= count; i++) {
      const fetchPUSH = singleURL ? `${url[0]}${i}` : url[i - 1];
//      console.log(fetchPUSH);
      buffer.push(
        await fetch(fetchPUSH)
        .catch(err => { console.log(`buffer.push().catch err : ${err}`) })
        .then(res => {
            return res.status === 200 ? res.json() : null;
          })
      )
    }

    console.log(buffer);
  };

  if (buffer_clear) cleanse(buffer);

  await fillerUp(buffer,url,count);
}

const fillPromises = (buffer , url = [], count = 0, append_mode = false) => {
  const singleURL = url.length === 1;

  if (!append_mode) cleanse(buffer);

  for (let i = 1; i <= count; i++) {
    const fetchPUSH = singleURL ? `${url[0]}${i}` : url[i - 1];
//    console.log(`${i - 1} ${count} ${fetchPUSH}`);
    buffer.push(
      fetch(fetchPUSH)
      .catch(err => { console.log(`buffer.push().catch err : ${err}`) })
      .then(res => {
          return res.status === 200 ? res.json() : null;
        })
    )
  }
};

const logObj = (obj) => console.log(`object [JSON]  : ${JSON.stringify(obj, undefined, 4)}`);

const lowerCase = (str) => str.toLowerCase(str);

const titleCase = (str) => {
    return str.toLowerCase().split(' ').map(function(word) {
        return word.replace(word[0], word[0].toUpperCase());
    }).join(' ');
}

/*  https://medium.com/@trisianto/react-query-how-to-memoize-results-from-usequeries-hook-eaed9a0ec700
    const dataSets = useArrayMemo(
    results.map((result) => result.data)
    );
*/
function useArrayMemo(array) {
  // this holds reference to previous value
  const ref = useRef();
  // check if each element of the old and new array match
  const areArraysConsideredTheSame =
    ref.current && array.length === ref.current.length
      ? array.every((element, i) => {
        return element === ref.current[i];
      })
    //initially there's no old array defined/stored, so set to false
    : false;
  useEffect(() => {
    //only update prev results if array is not deemed the same
    if (!areArraysConsideredTheSame) {
      ref.current = array;
    }
  }, [areArraysConsideredTheSame, array]);
  return areArraysConsideredTheSame ? ref.current : array;
}

export  {
          cleanse, block_Promises, fillPromises,
          fillPromises2, grabData, logObj,
          lowerCase, titleCase, useArrayMemo
        }