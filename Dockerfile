# Install extensions for vscode-server
FROM codercom/code-server:v2 as vscode

USER root
WORKDIR /
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
	--install-extension esbenp.prettier-vscode

## let any user have the access
RUN chmod -R a+rwx /usr/local/share/code-server

# Build tools for code-server to /go/bin
FROM golang:1.13 as gobin
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
FROM golang:1.13 as go3rdparty
## ToDo: to use go mod, set https://blog.golang.org/using-go-modules
RUN go get -d -v github.com/golang/protobuf/protoc-gen-go

# Finalize the image
FROM golang:1.13
MAINTAINER "Godev team"

RUN apt -y update
#go pprof needs this
RUN apt -y install graphviz

COPY --from=vscode /usr/local/share/code-server /usr/local/share/code-server
COPY --from=vscode /usr/local/bin/code-server /usr/local/bin/code-server
COPY --from=gobin /go/bin /go/bin
COPY --from=go3rdparty /go/src /go/src

WORKDIR /go

EXPOSE 8080

CMD code-server --user-data-dir /usr/local/share/code-server --auth password

