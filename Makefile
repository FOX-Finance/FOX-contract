set:
	npm install
	npx hardhat compile

reset:
	make clean
	npm install
	npx hardhat compile

clean:
	rm -rf artifacts
	rm -rf cache
	rm -rf node_modules
