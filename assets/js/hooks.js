let Hooks = {}

Hooks.HandPersistence = {
  mounted() {
    this.handleEvent("load_hand_from_storage", () => {
      const saved = localStorage.getItem("mahjong-hand")
      if (saved) {
        try {
          const tiles = JSON.parse(saved)
          this.pushEvent("restore_hand", { tiles })
        } catch (_) {}
      }
    })

    this.handleEvent("store_hand_to_storage", ({ tiles }) => {
      localStorage.setItem("mahjong-hand", JSON.stringify(tiles))
    })
  }
}

export default Hooks
