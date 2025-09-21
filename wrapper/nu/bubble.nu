export def "run" [
  command: string
  ...args: string
  --bubblewrap: string
] {
  let data = $in

  let command = $command | path expand
  let bubblewrap_args = [
    ...$data.raw
    ...($data.env | upsert PATH ($data.path | str join :) | each { transpose name value | each { [--setenv $in.name $in.value] } } | flatten)
  ]

  print $bubblewrap_args
  ^($bubblewrap | default bwrap) ...$bubblewrap_args $command ...$args
}

export def "base" [] {
  {
    env: {
    }
    path: []
    raw: [
      --unshare-all
      --clearenv
      --dev /dev
      --proc /proc
      --tmpfs /tmp
    ]
  }
}

export def "add command" [
  ...commands: string
] {
  let paths = $commands | each { which --all $in | where type == external | get 0.path | path expand | path dirname }
  $in | add store ...$paths | upsert path { append $paths }
}

export def "add store" [
  ...storepaths: path
] {
  let data = $in
  let deps = $storepaths | each { |store| nix-store -qR $store | lines } | flatten | uniq
  $deps | reduce --fold $data { |dep, acc| $acc | bind same $dep }
}

export def "add raw" [
  ...args: string
] {
  $in | update raw { append $args }
}

export def "bind same" [
  ...paths: path
  --writable
] {
  # $in | update raw { append ($paths | each { |path| {raw: []} | bind different $path $path } | flatten).raw }
  let data = $in

  if $writable {
    $paths | reduce --fold $data { |path, acc| $acc | bind different --writable  $path $path }
  } else {
    $paths | reduce --fold $data { |path, acc| $acc | bind different $path $path }
  }
}

export def "bind different" [
  src: path
  dest: path
  --writable
] {
  $in | update raw { append [(if $writable { --bind } else { --ro-bind }) $src $dest] }
}

export def "set env" [
  name: string
  value: string
] {
  $in | update raw { append [--setenv $name $value] }
}
