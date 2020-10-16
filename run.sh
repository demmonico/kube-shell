#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep, demmonico@gmail.com
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/kube-shell
#
# Kube-shell is set of Bash scripts aimed in help to connect / manage Kubernetes cluster using prepared Docker image, e.g. deployer image.
# Check README.md for usage examples
#
# FORMAT: ./run.sh [OPTIONS|FLAGS]
# Run ./run.sh --help for details or check README.md
#
#-----------------------------------------------------------#

RC='\033[0;31m'
YC='\033[0;33m'
NC='\033[0m' # No Color

CURRENT_HOST_VOLUME_MODE='readonly'
PORT_MAPPING=''
_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_YAML_PARSER="${_DIR}/parse_yaml_config.sh"
CONFIG_YAML_FILE="${_DIR}/config.yaml"


# read params
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      echo -e "COMMAND: ${YC}run.sh [OPTIONS|FLAGS]${NC}"
      echo -e "Pls create ${YC}config.yaml${NC} based on ${YC}config.example.yaml${NC} and check it for correct entries"
      echo "Options / flags:"
      cat "${BASH_SOURCE[0]}" | grep -E '\-\-[[:alnum:]]*\)'
      exit;;

    -c|--cluster) # cluster name
      if [ ! -z "$2" ]; then CLUSTER="$2"; fi
      shift;;
    -e|--env)     # environment name
      if [ ! -z "$2" ]; then ENV="$2"; fi
      shift;;

    --rw)         # current host volume mode sets to RW (default is readonly)
      CURRENT_HOST_VOLUME_MODE='';;
    -p|--port)    # map host port into shell
      if [ ! -z "$2" ]; then PORT_MAPPING="$2"; fi
      shift;;
    -a|--alias)   # create alias ksh at ~/.bash_profile
      if [ -z "$2" ]; then echo -e "${RC}Error:${NC} ALIAS param is required"; exit 1; fi
      ALIAS="$2"
      echo -e -n "Adding alias ${YC}${ALIAS}${NC} to ${YC}~/.bash_profile${NC} ... "
      echo -e "\n### kube-shell \nalias ${ALIAS}='${_DIR}/run.sh' \n" >> ~/.bash_profile
      echo "Done. Pls reload your current shell."
      exit;;

    *)
      echo -e "${RC}Error:${NC} invalid option -$1"
      exit 1;;
  esac
    shift
done

[ -z "${ENV}" ] && ENV='staging'

if [ -z "${CLUSTER}" ]; then
  echo -e "${RC}Error${NC}: CLUSTER param is required"
  exit 1
fi

if [ ! -f "${CONFIG_YAML_FILE}" ]; then
  echo -e "${RC}Error${NC}: config file '${YC}${CONFIG_YAML_FILE}${NC}' is not found. Pls check '${YC}config.example.yaml${NC}'"
  exit 1
fi



# read config
DOCKER_IMAGE="$( eval ${CONFIG_YAML_PARSER} ${CONFIG_YAML_FILE} "${CLUSTER}" "${ENV}" 'pull_image' )"
if [ -z "${DOCKER_IMAGE}" ]; then
  echo -e "${RC}Error${NC}: there are no '${YC}${CLUSTER}.${ENV}.pull_image${NC}' param in config file"
  exit 1
fi

# prepare
CURRENT_HOST_FOLDER="$(pwd)"
[ -n "${PORT_MAPPING}" ] && PORT_MAPPING=" -p ${PORT_MAPPING}"
DOCKER_ENV_FILE="$( eval ${CONFIG_YAML_PARSER} ${CONFIG_YAML_FILE} "${CLUSTER}" "${ENV}" 'env_file' )"
[ -n "${DOCKER_ENV_FILE}" ] && DOCKER_ENV_FILE="--env-file ${_DIR}/${DOCKER_ENV_FILE}"
echo -e "${YC}Running deployer ${RC}${DOCKER_IMAGE}${YC}. Mounting current folder ${RC}${CURRENT_HOST_FOLDER}${YC} as ${RC}/temp${YC} ... ${NC}"

# run deployer image
docker run -it \
  -u root \
  --workdir /temp \
  --mount "type=bind,source=${CURRENT_HOST_FOLDER},target=/temp${CURRENT_HOST_VOLUME_MODE:+,${CURRENT_HOST_VOLUME_MODE}}" \
  --mount type=bind,source=${_DIR}/pull_image/,target=/mounted \
  ${PORT_MAPPING} \
  ${DOCKER_ENV_FILE} -e CLUSTER=${CLUSTER} -e ENV=${ENV} \
  ${DOCKER_IMAGE} \
  /mounted/entrypoint.sh
