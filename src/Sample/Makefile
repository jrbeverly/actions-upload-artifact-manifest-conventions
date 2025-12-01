# Generic .NET entrypoint: never names a sln/project (dotnet resolves the
# one in this dir). Artifacts -> ./artifacts. Optional VERSION=x.y.z.
CONFIG    ?= Release
ARTIFACTS ?= artifacts

.PHONY: ci restore build test pack format format-check clean
ci: test pack
restore:
	dotnet restore
build: restore
	dotnet build -c $(CONFIG)
test: build
	dotnet test -c $(CONFIG) --logger "trx;LogFileName=test-results.trx"
pack: build
	dotnet pack -c $(CONFIG) -o $(ARTIFACTS) $(if $(VERSION),-p:Version=$(VERSION),)
format:
	dotnet format
format-check:
	dotnet format --verify-no-changes
clean:
	dotnet clean || true
	rm -rf $(ARTIFACTS)
