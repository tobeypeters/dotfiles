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

/*  Data.js
    Description:
        Data related functions
*/
import JsonPretty from 'react-json-pretty';

export const arrClear = (arr) => {
  if (Array.isArray(arr)) {
    arr.splice(0, arr.length);
  }
}

export const grabData = async (url) => {
  const response = await fetch(url);
  const results = response.status === 200 ? response.json() : null;
  return results;
}

export const prettyjson = (json) => (<JsonPretty json={json} />)

export const getStorage = (key) => {
  const gettest = JSON.parse(localStorage.getItem(key));
  // console.log(gettest);
  return JSON.parse(localStorage.getItem(key));
}

export const putStorage = (key, value) => {
  // console.log('puttest',key,value);
  localStorage.setItem(key, JSON.stringify(value));
}