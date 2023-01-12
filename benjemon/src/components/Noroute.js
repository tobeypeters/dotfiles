import { useMatch } from "react-router-dom";

export function Noroute() {
    const match = useMatch();
    console.log('match',match);

    // if (match) {
    //     console.log('yep',match);
    // }
    // else {
    //     console.log('nope',match);
    // }

  return (
    <div>Noroute</div>
  )
}