# clang path
case ${OSTYPE} in
  darwin*) # mac
    # LIBCLANG_PATH
    libclang_path_list=(${(z)$(mdfind -name libclang.dylib | grep llvm | sort)})
    if [[ 0 < $#libclang_path_list ]]; then
      export LIBCLANG_PATH=${libclang_path_list[-1]}
    fi

    # CLANG_HEADER_PATH
    clang_header_path_list=(${(z)$(mdfind -name clang | grep /lib/clang$ | grep llvm | sort)})
    if [[ 0 < $#clang_header_path_list ]]; then
      export CLANG_HEADER_PATH=${clang_header_path_list[-1]}
    fi

    ;;
  linux*)
    ;;
esac

