# clang path
case ${OSTYPE} in
  darwin*) # mac
    #clang_path_list=find /usr/local/ -name libclang.dylib | grep llvm | sort
    #if [[ 0 < clang_path_list[*] ]]; then
    #  export LIBCLANG_PATH=${clang_path_list[-1]}
    #fi
    ;;
  linux*)
    ;;
esac

