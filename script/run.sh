if [ $1 ]; then
  PORT=$1
else
  PORT='80'
fi

if [ $2 ]; then
  echo 'exporting mojo mode as "'$2'"'
  export MOJO_MODE=$2
fi

morbo /home/ath88/repos/Kolletilmelding/script/kolle --verbose --listen http://0.0.0.0:$PORT
