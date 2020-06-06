FROM golang:1.13.12 as builder

USER root
RUN apt -y update && apt -y install gcc

WORKDIR /root
RUN curl -o code-server.tar.gz https://github.com/cdr/code-server/releases/download/2.1698/code-server2.1698-vsc1.41.1-linux-x86_64.tar.gz
RUN mkdir code-server && tar -C code-server -xvf code-server.tar.gz --strip 1 && cp code-server/code-server /usr/bin && rm -rf code-server*
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
RUN go get -v github.com/stamblerre/gocode && ln -sf $GOPATH/bin/gocode $GOPATH/bin/gocode-gomod
RUN go get -v github.com/uudashr/gopkgs/cmd/gopkgs
RUN go get -v github.com/ramya-rao-a/go-outline
RUN go get -v github.com/acroca/go-symbols
RUN go get -v golang.org/x/tools/cmd/guru
RUN go get -v golang.org/x/tools/cmd/gorename
RUN go get -v github.com/fatih/gomodifytags
RUN go get -v github.com/haya14busa/goplay
RUN go get -v github.com/josharian/impl
RUN go get -v github.com/tylerb/gotype-live
RUN go get -v github.com/rogpeppe/godef
RUN go get -v github.com/zmb3/gogetdoc
RUN go get -v golang.org/x/tools/cmd/goimports
RUN go get -v github.com/sqs/goreturns
RUN go get -v golang.org/x/lint/golint
RUN go get -v github.com/cweill/gotests
RUN GO111MODULE=on go get -v github.com/golangci/golangci-lint/cmd/golangci-lint
RUN go get -v github.com/mgechev/revive
RUN go get -v github.com/go-delve/delve/cmd/dlv
RUN go get -v github.com/davidrjenni/reftools/cmd/fillstruct
RUN go get -v github.com/godoctor/godoctor
#gopls for future use
RUN go get -v golang.org/x/tools/gopls

# Prepare 3rd party dependency
## ToDo: to use go mod, see https://blog.golang.org/using-go-modules
RUN go get -d -v github.com/golang/protobuf/protoc-gen-go


# Finalize the image
FROM golang:1.13.12

USER root
#go pprof needs this
RUN apt -y update && apt -y install graphviz

COPY --from=builder /usr/bin/code-server /usr/bin/code-server
COPY --from=builder /usr/local/share/code-server /usr/local/share/code-server
COPY --from=builder /go/bin /go/bin
COPY --from=builder /go/src /go/src

WORKDIR /go

EXPOSE 8080

# empty the ENTRYPOINT
ENTRYPOINT []

#CMD /usr/bin/code-server --user-data-dir /usr/local/share/code-server --auth password --bind-addr 0.0.0.0:8080
CMD /usr/bin/code-server --user-data-dir /usr/local/share/code-server --auth password

