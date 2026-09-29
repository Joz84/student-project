require "test_helper"

class InscriptionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo inscription #{SecureRandom.hex(4)}")
    @existante = creer_eleve("20259500", "Timau")
  end

  test "le formulaire refuse un numéro déjà inscrit et dit quoi faire" do
    assert_no_difference -> { User.count } do
      post user_registration_path, params: { user: {
        email: "autre-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "Tehonopukeani",
        last_name: "Timau--Mare", student_number: "20259500", batch_id: @batch.id,
        password: "motdepasse", password_confirmation: "motdepasse"
      } }
    end
    assert_match "compte existant", response.body
    assert_match "Mot de passe oublié", response.body
  end

  test "un numéro libre passe" do
    assert_difference -> { User.count }, 1 do
      post user_registration_path, params: { user: {
        email: "neuf-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "Moana",
        last_name: "Faatau", student_number: "20259501", batch_id: @batch.id,
        password: "motdepasse", password_confirmation: "motdepasse"
      } }
    end
  end

  test "le numéro d'un compte désactivé reste réinscriptible" do
    @existante.update!(drop: true)
    assert_difference -> { User.count }, 1 do
      post user_registration_path, params: { user: {
        email: "retour-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "Tehonopukeani",
        last_name: "Timau--Mare", student_number: "20259500", batch_id: @batch.id,
        password: "motdepasse", password_confirmation: "motdepasse"
      } }
    end
  end
end
