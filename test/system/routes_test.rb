require "application_system_test_case"

class RoutesTest < ApplicationSystemTestCase
  setup { @user = users(:viajante) }

  test "escolher a rota preenche os km e dá pra trocar antes de salvar" do
    @user.routes.create!(name: "Volta do Guanabara", km: "3,55")
    sign_in_as @user

    visit new_walk_url
    select "Volta do Guanabara (3,55 km)", from: "Rota"
    assert_field "Quantos km?", with: "3.55"

    fill_in "Quantos km?", with: "4"
    click_on "Registrar caminhada"

    assert_no_field "Quantos km?"
    walk = @user.walks.order(:id).last
    assert_equal 4, walk.km
    assert_equal "Volta do Guanabara", walk.route.name
  end

  test "escolher a rota com tempo preenche horas e minutos, sem tempo limpa" do
    @user.routes.create!(name: "Volta longa", km: 8, duration: "1:31:00")
    @user.routes.create!(name: "Volta curta", km: 2)
    sign_in_as @user

    visit new_walk_url
    select "Volta longa (8 km)", from: "Rota"
    assert_field "Horas", with: "1"
    assert_field "Minutos", with: "31"
    assert_field "Segundos", with: ""

    select "Volta curta (2 km)", from: "Rota"
    assert_field "Horas", with: ""
    assert_field "Minutos", with: ""

    select "Volta longa (8 km)", from: "Rota"
    click_on "Registrar caminhada"

    assert_no_field "Quantos km?"
    assert_equal 5460, @user.walks.order(:id).last.duration_s
  end

  test "o print do Samsung Health vira o traçado da rota" do
    sign_in_as @user
    visit new_route_url
    fill_in "Nome da rota", with: "Volta do Guanabara"
    fill_in "Quantos km?", with: "3,55"
    attach_file "Print do mapa", file_fixture("rota_guanabara.png")

    assert_selector "[data-trace-status='ok']"
    min_x, min_y, max_x, max_y = trace_bounds
    assert_in_delta 215, min_x, 40
    assert_in_delta 815, max_x, 40
    assert_in_delta 230, min_y, 40
    assert_in_delta 750, max_y, 40
    assert_text "Saiu errado? Toque na linha do trajeto."

    click_on "Salvar rota"

    assert_selector "[data-route-card] svg polyline"
    route = @user.routes.last
    assert_equal "photo", route.trace_source
    assert Route::Trace.valid?(route.trace)
  end

  test "print no modo escuro com linha azul e cruzamentos sai inteiro" do
    sign_in_as @user
    visit new_route_url
    attach_file "Print do mapa", file_fixture("rota_escura.jpg")

    assert_selector "[data-trace-status='ok']"
    min_x, min_y, max_x, max_y = trace_bounds
    assert_in_delta 45, min_x, 40
    assert_in_delta 960, max_x, 40
    assert_in_delta 35, min_y, 40
    assert_in_delta 640, max_y, 40
  end

  test "tocar na linha refaz o traçado com a cor tocada" do
    sign_in_as @user
    visit new_route_url
    attach_file "Print do mapa", file_fixture("rota_guanabara.png")
    assert_selector "[data-trace-status='ok']"

    canvas = find("[data-route-trace-target='canvas']")
    scale = canvas.evaluate_script("this.clientWidth") / 1080.0
    page.execute_script("document.querySelector('[data-controller=\"route-trace\"]').removeAttribute('data-trace-status')")
    canvas.click(x: (800 * scale).round, y: (460 * scale).round, offset: :top_left)

    assert_selector "[data-trace-status='ok']"
  end

  test "imagem sem trajeto salva a rota com a arte de reserva" do
    sign_in_as @user
    visit new_route_url
    fill_in "Nome da rota", with: "Volta cinza"
    fill_in "Quantos km?", with: "2"
    attach_file "Print do mapa", file_fixture("cinza.png")

    assert_selector "[data-trace-status='empty']"
    assert_text "Tocar na linha do trajeto"

    click_on "Salvar rota"

    assert_selector "[data-route-card] img[src*='art/routes/placeholder']"
    assert_nil @user.routes.last.trace
  end

  test "trocar o print por um arquivo que não abre limpa o traçado" do
    sign_in_as @user
    route = @user.routes.create!(name: "Volta", km: 3, trace: [ [ 0, 0 ], [ 1, 1 ] ], trace_source: "photo")
    visit edit_route_url(route)
    attach_file "Print do mapa", file_fixture("rota_guanabara.png")
    assert_selector "[data-trace-status='ok']"

    attach_file "Print do mapa", file_fixture("quebrada.png")

    assert_selector "[data-trace-status='empty']"
    assert_equal "[]", trace_field.value
    assert_no_selector "[data-route-trace-target='preview'] svg"

    click_on "Salvar"

    assert_selector "[data-route-card] img[src*='art/routes/placeholder']"
    assert_nil route.reload.trace
    assert_nil route.trace_source
  end

  test "tocar no fundo do mapa não trava e cai no vazio" do
    sign_in_as @user
    visit new_route_url
    attach_file "Print do mapa", file_fixture("rota_guanabara.png")
    assert_selector "[data-trace-status='ok']"

    canvas = find("[data-route-trace-target='canvas']")
    scale = canvas.evaluate_script("this.clientWidth") / 1080.0
    page.execute_script("document.querySelector('[data-controller=\"route-trace\"]').removeAttribute('data-trace-status')")
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    canvas.click(x: (560 * scale).round, y: (440 * scale).round, offset: :top_left)

    assert_selector "[data-trace-status='empty']"
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 2
    assert_equal "[]", trace_field.value
  end

  private
    def sign_in_as(user)
      visit root_url
      fill_in "Email", with: user.email_address
      click_on "Receber código"
      assert_text "CÓDIGO"
      fill_in "Código de 6 dígitos", with: user.auth_tokens.order(:created_at).last.code
      click_on "Entrar"
      assert_text "Começar jornada"
    end

    def trace_field
      find("[data-route-trace-target='field']", visible: false)
    end

    def trace_bounds
      find("[data-trace-bounds]")["data-trace-bounds"].split(",").map(&:to_f)
    end
end
