compile:
	npx hardhat clean
	npx hardhat compile

set:
	npm install
	npx hardhat clean
	npx hardhat compile

reset:
	make clean
	make set

clean:
	rm -rf artifacts
	rm -rf cache
	rm -rf node_modules
