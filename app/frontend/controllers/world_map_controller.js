import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // O mapa é mais alto que a tela: abre já mostrando onde o viajante está.
  connect() {
    this.element.querySelector(".world-map__node--current, .world-map__node--boss")
      ?.scrollIntoView({ block: "center" })
  }

  // A bolinha abre a janela da fase; sem suporte a <dialog> o link só pula pra ela.
  open(event) {
    const dialog = document.getElementById(event.currentTarget.getAttribute("href").slice(1))
    if (!dialog?.showModal) return

    event.preventDefault()
    dialog.showModal()
  }

  // Clique fora do conteúdo cai no próprio <dialog>, que é o fundo escuro.
  closeOnBackdrop({ target }) {
    if (target.tagName === "DIALOG") target.close()
  }
}
