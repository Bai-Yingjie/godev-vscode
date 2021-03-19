FROM codercom/code-server:3.9.1 as builder

ENV GOLANG_VERSION=1.16.2
ENV GOPATH "/go"
ENV GO111MODULE "on"
ENV PATH "/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER root
RUN apt -y update && apt -y install gcc

WORKDIR $GOPATH
RUN curl -o go.tar.gz -L https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz
RUN tar -C /usr/local -xf go.tar.gz && rm -f go.tar.gz

RUN mkdir -p /usr/local/share/code-server
RUN code-server \
	--user-data-dir /usr/local/share/code-server \
	--install-extension golang.go \
	--install-extension ms-python.python \
	--install-extension ms-vscode.cpptools \
	--install-extension formulahendry.code-runner \
	--install-extension eamodio.gitlens \
	--install-extension coenraads.bracket-pair-colorizer \
	--install-extension oderwat.indent-rainbow \
	--install-extension windmilleng.vscode-go-autotest \
	--install-extension vscode-icons-team.vscode-icons \
	--install-extension esbenp.prettier-vscode \
	--install-extension ryu1kn.text-marker \
	--install-extension streetsidesoftware.code-spell-checker

## set default settings
COPY vscodesettings.json /usr/local/share/code-server/User/settings.json
COPY vscodekeybindings.json /usr/local/share/code-server/User/keybindings.json

## let any user have the access
RUN chmod -R a+rwx /usr/local/share/code-server

## see https://github.com/golang/vscode-go/blob/master/src/goTools.ts
## and https://github.com/golang/vscode-go/blob/master/docs/tools.md
## and https://github.com/golang/vscode-go/blob/master/docs/gopls.md
RUN go get -ldflags "-s -w" -trimpath -v golang.org/x/lint/golint
RUN go get -ldflags "-s -w" -trimpath -v golang.org/x/tools/gopls
RUN go get -ldflags "-s -w" -trimpath -v github.com/go-delve/delve/cmd/dlv
RUN go get -ldflags "-s -w" -trimpath -v github.com/ramya-rao-a/go-outline
RUN go get -ldflags "-s -w" -trimpath -v github.com/acroca/go-symbols
RUN go get -ldflags "-s -w" -trimpath -v golang.org/x/tools/cmd/goimports
## protoc plugin for go
RUN go get -ldflags "-s -w" -trimpath -v github.com/golang/protobuf/protoc-gen-go

# Finalize the image
FROM codercom/code-server:3.9.1

ENV GOROOT "/usr/local/go"
ENV GOPATH "/go"
#ENV GOPROXY "https://goproxy.cn,direct"
ENV PATH "/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER root
## go pprof needs graphviz
RUN apt -y update && apt -y install build-essential graphviz protobuf-compiler vim

COPY --from=builder /usr/local/share/code-server /usr/local/share/code-server
COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /go/bin /go/bin

## v3.5.0 needs this
RUN mkdir -p /usr/User && chmod a+rwx /usr/User

WORKDIR /go
EXPOSE 8080
## empty the ENTRYPOINT
ENTRYPOINT []

CMD /usr/bin/code-server --user-data-dir /usr/local/share/code-server --auth password --bind-addr 0.0.0.0:8080 --disable-update-check
