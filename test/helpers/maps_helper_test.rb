require "test_helper"

class MapsHelperTest < ActionView::TestCase
  setup { @region = World.current.regions.first }

  test "um nó por fase, de baixo pra cima na trilha do mundo" do
    nodes = world_nodes(@region)

    assert_equal @region.phases, nodes.map(&:first)
    assert_equal [ 140, 570 ], nodes.first.last
    assert_equal [ 140, 60 ], nodes.last.last
  end

  test "no mapa deitado os nós vão da esquerda pra direita" do
    nodes = world_nodes(@region, :wide).map(&:last)

    assert_equal [ 120, 330 ], nodes.first
    assert_equal [ 830, 72 ], nodes.last
    assert_equal nodes.map(&:first).sort, nodes.map(&:first)
  end

  test "rótulo do mapa em pé fica do lado livre, no deitado fica embaixo do nó" do
    assert_equal [ 78, 104, "start" ], world_label(:tall, 60, 100, nil)
    assert_equal [ 162, 100, "end" ], world_label(:tall, 180, 100, "vencida")
    assert_equal [ 400, 130, "middle" ], world_label(:wide, 400, 100, nil)
  end

  test "trilha dourada vai até o nó da fase atual" do
    user = users(:viajante)
    walk_steady user, 90, until_days_ago: 2
    walk_on user, 1, 12

    assert_in_delta 0.2, world_walked_fraction(@region, user.journey)
  end

  test "região completa tem a trilha toda dourada" do
    user = users(:viajante)
    travel_whole_world user

    assert_equal 1, world_walked_fraction(@region, user.journey)
  end

  test "região que não é a atual nem completa fica sem trilha dourada" do
    with_world(test_world) do
      region = World.current.regions.last

      assert_equal 0, world_walked_fraction(region, users(:viajante).journey)
    end
  end

  test "rótulo fica do lado livre do nó" do
    assert_equal [ 78, "start" ], world_label_position(60)
    assert_equal [ 162, "end" ], world_label_position(180)
  end

  test "legenda do nó" do
    phase, legendary = @region.phases.values_at(0, -1)

    assert_equal "vencida", world_node_caption(phase, :completed)
    assert_equal "você está aqui", world_node_caption(phase, :current)
    assert_equal "o chefe espera", world_node_caption(phase, :boss)
    assert_nil world_node_caption(phase, :upcoming)
    assert_equal "lendária", world_node_caption(legendary, :upcoming)
  end
end
