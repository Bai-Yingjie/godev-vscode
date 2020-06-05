FROM codercom/code-server:latest

ENV GOLANG_VERSION=1.13.12
ENV GOPATH "/go"
ENV PATH "/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt -y update
#go pprof needs this
RUN apt -y install graphviz

USER root
WORKDIR /
RUN curl -o go.tar.gz https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz
RUN tar -C /usr/local -xf go.tar.gz && rm -f go.tar.gz
RUN mkdir -p $GOPATH/src $GOPATH/bin && chmod -R 777 $GOPATH
RUN mkdir -p /usr/local/share/code-server
RUN code-server \
	--user-data-dir /usr/local/share/code-server \
	--install-extension ms-vscode.Go \
	--install-extension ms-python.python \
	--install-extension ms-vscode.cpptools \
	--install-extension formulahendry.code-runner \
	--install-extension eamodio.gitlens \
	--install-extension coenraads.bracket-pair-colorizer \
	--install-extension oderwat.indent-rainbow \
	--install-extension windmilleng.vscode-go-autotest \
	--install-extension defaltd.go-coverage-viewer \
	--install-extension vscode-icons-team.vscode-icons \
	--install-extension esbenp.prettier-vscode \
	--install-extension streetsidesoftware.code-spell-checker

## let any user have the access
RUN chmod -R a+rwx /usr/local/share/code-server

## see https://github.com/microsoft/vscode-go/blob/master/src/goTools.ts
RUN go get -u -v github.com/stamblerre/gocode && ln -sf $GOPATH/bin/gocode $GOPATH/bin/gocode-gomod
RUN go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs
RUN go get -u -v github.com/ramya-rao-a/go-outline
RUN go get -u -v github.com/acroca/go-symbols
RUN go get -u -v golang.org/x/tools/cmd/guru
RUN go get -u -v golang.org/x/tools/cmd/gorename
RUN go get -u -v github.com/fatih/gomodifytags
RUN go get -u -v github.com/haya14busa/goplay
RUN go get -u -v github.com/josharian/impl
RUN go get -u -v github.com/tylerb/gotype-live
RUN go get -u -v github.com/rogpeppe/godef
RUN go get -u -v github.com/zmb3/gogetdoc
RUN go get -u -v golang.org/x/tools/cmd/goimports
RUN go get -u -v github.com/sqs/goreturns
RUN go get -u -v golang.org/x/lint/golint
RUN go get -u -v github.com/cweill/gotests
RUN go get -u -v github.com/golangci/golangci-lint/cmd/golangci-lint
RUN go get -u -v github.com/mgechev/revive
RUN go get -u -v github.com/go-delve/delve/cmd/dlv
RUN go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct
RUN go get -u -v github.com/godoctor/godoctor
#gopls for future use
#RUN go get -u -v golang.org/x/tools/gopls

# Prepare 3rd party dependency
## ToDo: to use go mod, see https://blog.golang.org/using-go-modules
RUN go get -d -v github.com/golang/protobuf/protoc-gen-go

WORKDIR /go

EXPOSE 8080

CMD dumb-init fixuid -q /usr/bin/code-server --user-data-dir /usr/local/share/code-server --auth password
