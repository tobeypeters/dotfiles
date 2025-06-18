import { useState, useEffect } from "react";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import "./App.css";

const perPage = 175;

const LOCAL_STORAGE_KEYS = {
  SELECTED_TYPE: "selectedType",
  SELECTED_SET: "selectedSet",
  FAVORITES: "favorites",
};

const getLocalStorageItem = (key, fallback) => {
  try {
    const item = localStorage.getItem(key);
    return item ? JSON.parse(item) : fallback;
  } catch (error) {
    console.error(`Failed to read ${key} from localStorage`, error);
    return fallback;
  }
};

const App = () => {
  // Filtering state
  const [sets, setSets] = useState([]);
  const [setTypes, setSetTypes] = useState([]);
  const [setType, setSetType] = useState(
    getLocalStorageItem(LOCAL_STORAGE_KEYS.SELECTED_TYPE, "all")
  );
  const [setCode, setSetCode] = useState(
    getLocalStorageItem(LOCAL_STORAGE_KEYS.SELECTED_SET, "")
  );

  // Cards state
  const [cards, setCards] = useState([]);
  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalCards, setTotalCards] = useState(0);
  const [selectedCard, setSelectedCard] = useState(null);
  const [loading, setLoading] = useState(false);

  // Favorites state
  const [favorites, setFavorites] = useState(() =>
    getLocalStorageItem(LOCAL_STORAGE_KEYS.FAVORITES, [])
  );

  useEffect(() => {
    const fetchSets = async () => {
      try {
        const res = await fetch("https://api.scryfall.com/sets");
        if (!res.ok) throw new Error("Failed to fetch sets.");
        const data = await res.json();
        const relevant = data.data
          .filter((s) => s.set_type !== "token" && s.set_type !== "memorabilia" && s.released_at)
          .sort((a, b) => new Date(a.released_at) - new Date(b.released_at));
        const types = Array.from(new Set(relevant.map((s) => s.set_type))).sort();
        setSetTypes(types);
        setSets(relevant);

        const defaultSet = relevant.find(s => s.set_type === setType)?.code || relevant[0]?.code || "";
        setSetCode(defaultSet);
        localStorage.setItem("selectedSet", defaultSet);
      } catch (err) {
        console.error(err);
        toast.error("Failed to fetch MTG sets.");
      }
    };
    fetchSets();
  }, [setType]);

  useEffect(() => {
    localStorage.setItem("selectedType", setType);
    const filtered = setType === "all" ? sets : sets.filter((s) => s.set_type === setType);
    if (filtered.length > 0) {
      const firstSet = filtered[0].code;
      setSetCode(firstSet);
      localStorage.setItem("selectedSet", firstSet);
      setCurrentPage(1);
      setSearch("");
    }
  }, [setType, sets]);

useEffect(() => {
  const fetchCardsBySet = async () => {
    if (!setCode) return;
    try {
      setLoading(true);
      const res = await fetch(`https://api.scryfall.com/cards/search?q=e%3A${setCode}&page=${currentPage}`);
      if (!res.ok) throw new Error("Failed to fetch cards.");
      const data = await res.json();
      setCards(data.data || []);
      setTotalCards(data.total_cards || data.total || 0);
    } catch (err) {
      console.error(err);
      toast.error("Failed to fetch cards.");
    } finally {
      setLoading(false);
    }
  };

  const fetchCardsBySearch = async () => {
    try {
      setLoading(true);
      const res = await fetch(
        `https://api.scryfall.com/cards/search?q=${encodeURIComponent(search)}&unique=prints&page=${currentPage}`
      );
      if (!res.ok) throw new Error("Failed to fetch search results.");
      const data = await res.json();
      setCards(data.data || []);
      setTotalCards(data.total_cards || data.total || 0);
    } catch (err) {
      console.error(err);
      toast.error("Failed to fetch search results.");
    } finally {
      setLoading(false);
    }
  };

  if (search.trim()) {
    fetchCardsBySearch();
  } else {
    fetchCardsBySet();
  }
}, [setCode, currentPage, search]);


  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === "Escape") setSelectedCard(null);
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [currentPage]);

  const toggleFavorite = (card) => {
    const exists = favorites.find((c) => c.id === card.id);
    const updated = exists
      ? favorites.filter((c) => c.id !== card.id)
      : [...favorites, card];
    setFavorites(updated);
    localStorage.setItem("favorites", JSON.stringify(updated));
  };

  const isFavorite = (card) => favorites.some((c) => c.id === card.id);

  const filteredSets = setType === "all" ? sets : sets.filter((s) => s.set_type === setType);
  const totalPages = Math.ceil(totalCards / perPage);

  const paginate = () => {
    const pages = [];
    const maxVisible = 7;
    const half = Math.floor(maxVisible / 2);

    const start = Math.max(2, currentPage - half);
    const end = Math.min(totalPages - 1, currentPage + half);

    if (currentPage > 1) pages.push("first", "prev");
    pages.push(1);
    if (start > 2) pages.push("...");
    for (let i = start; i <= end; i++) pages.push(i);
    if (end < totalPages - 1) pages.push("...");
    if (totalPages > 1) pages.push(totalPages);
    if (currentPage < totalPages) pages.push("next", "last");
    return pages;
  };

  return (
    <div className="app">
      <ToastContainer />

      <div className="header">
        <img src="/images/mtgshield.png" alt="MTG Shield" className="corner-image" />
        <img src="/images/mtgscryetitlesmall.png" alt="MTG Scrye Title" className="title-image" />
      </div>

      <form
        className="controls"
        onSubmit={(e) => {
          e.preventDefault();
          setCurrentPage(1);
        }}
      >
        <select
          value={setType}
          onChange={(e) => {
            setSetType(e.target.value);
            setSearch("");
          }}
        >
          <option value="all">All Set Types</option>
          {setTypes.map((type) => (
            <option key={type} value={type}>
              {type.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase())}
            </option>
          ))}
        </select>

        <select
          value={setCode}
          onChange={(e) => {
            setSetCode(e.target.value);
            setCurrentPage(1);
            setSearch("");
          }}
        >
          {filteredSets.map((s) => (
            <option key={s.code} value={s.code}>
              {s.name} ({s.code.toUpperCase()}) – {new Date(s.released_at).getFullYear()}
            </option>
          ))}
        </select>

        <input
          type="text"
          placeholder="Search cards..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setCurrentPage(1);
            setSetType("all");
          }}
        />
        <button type="submit">Search</button>
      </form>

      {loading && <div className="loading">Loading cards...</div>}

      <div className="card-grid">
        {cards.map((card) => (
          <div className="card" key={card.id}>
            {card.image_uris?.normal ? (
              <img
                src={card.image_uris.normal}
                alt={card.name}
                onClick={() => setSelectedCard(card)}
              />
            ) : (
              <p>No image</p>
            )}
            <p>{card.name}</p>
            {search && <p style={{ fontSize: "0.85rem", color: "#ccc" }}>{card.set_name}</p>}
          </div>
        ))}
      </div>

      {totalPages > 1 && (
        <div className="pagination">
          {paginate().map((page, i) => {
            const isEllipsis = page === "...";

            const buttonProps = {
              key: i,
              onClick: () => {
                if (typeof page === "number") {
                  setCurrentPage(page);
                } else {
                  setCurrentPage(
                    page === "first" ? 1 :
                    page === "prev" ? Math.max(1, currentPage - 1) :
                    page === "next" ? Math.min(totalPages, currentPage + 1) :
                    page === "last" ? totalPages : currentPage
                  );
                }
              },
              className: page === currentPage ? "active" : ""
            };

            return isEllipsis ? (
              <span key={i} className="ellipsis">…</span>
            ) : (
              <button {...buttonProps}>
                {typeof page === "string"
                  ? { first: "« First", prev: "‹ Prev", next: "Next ›", last: "Last »" }[page]
                  : page}
              </button>
            );
          })}
        </div>
      )}

      {selectedCard && (
        <div className="modal" onClick={() => setSelectedCard(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-left">
              {selectedCard.image_uris?.normal && (
                <img src={selectedCard.image_uris.normal} alt={selectedCard.name} style={{ backgroundColor: "#1e1e1e" }} />
              )}
            </div>
            <div className="modal-right">
              <h2>{selectedCard.name}</h2>
              <p>{selectedCard.type_line}</p>
              <p>{selectedCard.oracle_text}</p>
              {selectedCard.prices?.usd && (
                <p><strong>Price:</strong> ${selectedCard.prices.usd}</p>
              )}
              <div className="modal-buttons">
                <button onClick={() => setSelectedCard(null)}>Close</button>
                <button onClick={() => toggleFavorite(selectedCard)}>
                  {isFavorite(selectedCard) ? "★ Remove Favorite" : "☆ Add to Favorites"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {favorites.length > 0 && (
        <div className="favorites">
          <h2>★ Favorites</h2>
          <div className="card-grid">
            {favorites.map((card) => (
              <div className="card" key={card.id}>
                {card.image_uris?.normal ? (
                  <img
                    src={card.image_uris.normal}
                    alt={card.name}
                    onClick={() => setSelectedCard(card)}
                  />
                ) : (
                  <p>No image</p>
                )}
                <p>{card.name}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default App;
