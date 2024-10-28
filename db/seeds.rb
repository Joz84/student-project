Exercice.destroy_all
Ticket.destroy_all
Course.destroy_all
Card.destroy_all
List.destroy_all
Team.destroy_all
Rating.destroy_all
Project.destroy_all
User.destroy_all

User.create!(admin: true, email: "dev@mihivai.com", password: 'azerty', first_name: "Dev", last_name: "Upf", student_number: 1, teacher: true, cw_nickname: "")  
User.create!(email: "student@gmail.com", password: 'azerty', first_name: "Bob", last_name: "Upf", student_number: 2)

Project.create!(name: "robot", description: "Blabla", subject: 1, max_booking: 4, author: 'Albert Colo', active: true)
Project.create!(name: "meteo", description: "Blabla", subject: 1, max_booking: 4, author: 'Albert Colo', active: true)
Project.create!(name: "aquaponing", description: "Blabla", subject: 1, max_booking: 4, author: 'Albert Colo', active: true)
Project.create!(name: "Chimie1", description: "Blabla", subject: 1, max_booking: 4, author: 'Albert Colo', active: true)
Project.create!(name: "Chimie2", description: "Blabla", subject: 1, max_booking: 4, author: 'Albert Colo', active: true)
Project.create!(name: "Totem", description: "Blabla", subject: 1, max_booking: 4, author: 'Albert Colo', active: true)

Team.create!(name: "Les cocos") 

Card.create!(
  name: "Recherche biblio", 
  description: "Ceci est une description", 
  list: List.first
)

Course.create!(
  slides_link:  "https://docs.google.com/presentation/d/e/2PACX-1vS1R7VMYHQpITtnmw3KhmBNKfuNYY0btAxaSvvQgtnAs-stnSgNcEAW-XkXm4oXeLucyP87eyLCKszs/embed?start=false&loop=false&delayms=3000", 
  position: 1, 
  ticket_activation: false, 
  name: "1er cours"
)

Course.create!(
  slides_link:  "https://docs.google.com/presentation/d/e/2PACX-1vS1R7VMYHQpITtnmw3KhmBNKfuNYY0btAxaSvvQgtnAs-stnSgNcEAW-XkXm4oXeLucyP87eyLCKszs/embed?start=false&loop=false&delayms=3000", 
  position: 2, 
  ticket_activation: true, 
  name: "2eme cours"
)

Ticket.create!(user: User.last, content: "Ca marche pas!")
Ticket.create!(user: User.last, content: "Ca marche tjr pas!")

Exercice.create!(name: "Find the position!", cw_token: "5808e2006b65bff35500008f", position: 1, course: Course.first, kata: 8)
Exercice.create!(name: "Double Char", cw_token: "56b1f01c247c01db92000076", position: 2, course: Course.first, kata: 8)
Exercice.create!(name: "Find the position2!", cw_token: "5808e2006b65bff35500008f", position: 1, course: Course.last, kata: 8)
Exercice.create!(name: "Double Char2", cw_token: "56b1f01c247c01db92000076", position: 2, course: Course.last, kata: 8)