if [[ "$EUID" == "0" ]]; then
   echo "Run this script without sudo!"
   exit 1
fi
