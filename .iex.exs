alias GameKeeper.Basketball.Team
alias GameKeeper.EventProcessing
alias GameKeeper.Games
alias GameKeeper.Repo

home = %Team{
  id: Ecto.UUID.generate(),
  name: "Home"
}

away = %Team{
  id: Ecto.UUID.generate(),
  name: "Away"
}
