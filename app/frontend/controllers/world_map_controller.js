import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // O mapa em pé do celular é mais alto que a tela: se o viajante ficou fora
  // dela, abre já mostrando onde ele está. O deitado do computador cabe inteiro.
  connect() {
    const here = [ ...this.element.querySelectorAll(".world-map__node--current, .world-map__node--boss") ]
      .find(node => node.getClientRects().length > 0)
    if (!here) return

    const { top, bottom } = here.getBoundingClientRect()
    if (top < 0 || bottom > window.innerHeight - 80) here.scrollIntoView({ block: "center" })
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
