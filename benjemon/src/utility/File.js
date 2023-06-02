const isStr = (obj) => typeof obj === 'string';

export async function saveJSON(source,destination) {
  console.log('saveJSON',source,destination);
  if (arguments.length && isStr(source) &&
        isStr(destination)) {

        console.log('source',source);

        fetch(destination, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(source)
        })
        .then(response => {
          console.log('here',response);
          if (response.ok) {
            console.log('JSON data saved successfully.');
          } else {
            console.error('Failed to save JSON data.');
          }
        })
        .catch(error => {
          console.error('Error:', error);
        })


//           console.log('arguments',arguments);
// // // Step 1: Fetch the JSON data from the server
// await fetch(source)
//   .then(response => {
//     if (!response.ok) {
//       throw new Error('Failed to fetch data');
//     }
//     return response.json();
//   })
//   .then(data => {

//   })
//   .catch(error => {
//     console.error('Error downloading data:', error);
//   });



}


}