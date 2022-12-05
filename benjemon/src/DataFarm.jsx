import { createContext, useReducer } from "react"

export const movesReducer = (state, action) => {
    switch (action.type) {
        // case "assign":
        //     return { ...state, data: state.payload };
        // case "clear":
        //     return { data: [] };
          default:
        return state;
    }
}
export const MovesContext = createContext({
  state: [], dispatch: () => []
});
export const MovesProvider = ({ children }) => {
  const [state, dispatch] = useReducer(movesReducer, { data: [] });

  return (
    <MovesContext.Provider value={[ state, dispatch ]}>
    	{ children }
    </MovesContext.Provider>
  )
}