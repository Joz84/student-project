ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Fabriques communes. Chaque test construit ses données : la base de test
    # n'est pas peuplée de fixtures, et les mêmes trois lignes se recopiaient
    # dans chaque fichier.
    def creer_eleve(numero, nom = "Eleve", batch: @batch, **attrs)
      User.create!(email: "eleve-#{SecureRandom.hex(6)}@etudiant.upf.pf",
                   first_name: "Test", last_name: nom, student_number: numero,
                   batch: batch, password: "motdepasse", **attrs)
    end

    def creer_prof(nom = "Fesseur", batch: @batch)
      creer_eleve(format("9%07d", SecureRandom.random_number(10_000_000)), nom,
                  batch: batch, teacher: true)
    end

    # Sans cela l'application rend ses propres pages d'erreur, qui masquent la
    # cause réelle d'un échec.
    def montrer_les_erreurs!
      Rails.application.env_config["action_dispatch.show_exceptions"] = :none
    end
  end
end
