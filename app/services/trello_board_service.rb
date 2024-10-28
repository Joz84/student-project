# app/services/trello_board_service.rb

require 'rest-client'
require 'json'

class TrelloBoardService
  TRELLO_API_URL = "https://api.trello.com/1"
  
  def initialize(api_key, token)
    @api_key = api_key
    @token = token
  end

  def create_board_with_lists
    board_id = create_board("Mon Nouveau Tableau")
    return unless board_id

    create_lists(board_id)
    make_board_public(board_id)

    "https://trello.com/b/#{board_id}"
  end

  private

  def create_board(name)
    url = "#{TRELLO_API_URL}/boards/"

    params = {
      name: name,
      key: @api_key,
      token: @token
    }

    begin
      response = RestClient.post(url, params)
      board = JSON.parse(response.body)
      puts "Tableau créé avec succès ! ID du tableau : #{board['id']}"
      board['id']
    rescue RestClient::ExceptionWithResponse => e
      puts "Erreur lors de la création du tableau : #{e.response}"
      nil
    end
  end

  def create_lists(board_id)
    list_names = ["Tâches à faire", "Tâches en cours", "Tâches Finalisées"]

    list_names.each do |list_name|
      url = "#{TRELLO_API_URL}/lists"

      params = {
        name: list_name,
        idBoard: board_id,
        key: @api_key,
        token: @token
      }

      begin
        response = RestClient.post(url, params)
        created_list = JSON.parse(response.body)
        puts "Liste créée avec succès : #{created_list['name']} (ID : #{created_list['id']})"
      rescue RestClient::ExceptionWithResponse => e
        puts "Erreur lors de la création de la liste '#{list_name}' : #{e.response}"
      end
    end
  end

  def make_board_public(board_id)
    url = "#{TRELLO_API_URL}/boards/#{board_id}"

    # Rendre le tableau public
    params_visibility = {
      "prefs/permissionLevel" => "public",
      key: @api_key,
      token: @token
    }

    # Autoriser les invitations pour rejoindre le tableau
    params_invitations = {
      "prefs/invitations" => "members",
      key: @api_key,
      token: @token
    }

    begin
      # Rendre le tableau public
      RestClient.put(url, params_visibility)
      puts "Le tableau est maintenant public."

      # Autoriser les invitations publiques
      RestClient.put(url, params_invitations)
      puts "Les utilisateurs disposant du lien peuvent maintenant rejoindre et modifier le tableau."
    rescue RestClient::ExceptionWithResponse => e
      puts "Erreur lors de la mise à jour des permissions : #{e.response}"
    end
  end
end
