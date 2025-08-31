export def edit_repo [
  apply: closure
  # file: path = (path self ./repo.json)
  file: path = ./repo.json
] {
  if not ($file | path exists) {
    echo "{}" | save $file
  }
  let data = open $file
  do $apply $data
    | to json 
    | save -f $file
}

export def maven_name_to_url [
  maven_base_url: string
  name: string
] {
  let splited = $name | split row ":"
  let orgs = $splited.0 | split row "."
  let artifact_name = $splited.1
  let artifact_version = $splited.2

  [ $maven_base_url ...$orgs $artifact_name $artifact_version $"($artifact_name)-($artifact_version).jar" ] | str join "/"
}
