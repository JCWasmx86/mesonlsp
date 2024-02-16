#include "lexer.hpp"
#include "utils.hpp"

#include <cstddef>
#include <filesystem>
#include <format>
#include <fstream>
#include <iostream>
#include <numeric>
#include <utility>
#include <vector>

std::pair<double, double>
computeLinearEquation(const std::vector<std::pair<size_t, size_t>> &points) {
  size_t sumX = 0;
  size_t sumY = 0;
  size_t sumXY = 0;
  size_t sumXSquare = 0;
  size_t nPoints = points.size();

  for (const auto &[pX, pY] : points) {
    sumX += pX;
    sumY += pY;
    sumXY += pX * pY;
    sumXSquare += pX * pX;
  }

  double slope = (double)(nPoints * sumXY - sumX * sumY) /
                 (double)(nPoints * sumXSquare - sumX * sumX);
  double yIntercept = ((double)sumY - slope * (double)sumX) / (double)nPoints;

  return std::make_pair(slope, yIntercept);
}

int main(int /*argc*/, char **argv) {
  std::filesystem::path listingsFile = argv[1];
  std::string line;
  std::ifstream inputFile(listingsFile);
  std::vector<std::pair<size_t, size_t>> pairs;
  std::vector<size_t> stringLengths;
  std::vector<double> deviationsInPercent;
  size_t totalExpectedTokens = 0;
  size_t totalRealTokens = 0;
  size_t totalFiles = 0;
  size_t totalLessThanExpected = 0;
  size_t totalMoreThanExpected = 0;
  size_t exact = 0;
  size_t nIdentifiers = 0;
  size_t identifierLengthTotal = 0;
  size_t nNumbers = 0;
  size_t numberLengthTotal = 0;
  while (std::getline(inputFile, line)) {
    auto contents = readFile(line);
    Lexer lexer(contents);
    auto guessed = Lexer::guessTokensCount(contents.size());
    lexer.tokenize();
    auto total = lexer.tokens.size();
    totalExpectedTokens += guessed;
    totalRealTokens += total;
    totalFiles++;
    if (guessed == total) {
      exact++;
    } else if (guessed > total) {
      totalLessThanExpected++;
    } else {
      totalMoreThanExpected++;
    }
    auto percentage = ((double)total) / (double)guessed - 1.0;
    deviationsInPercent.push_back(percentage);
    for (const auto &tok : lexer.tokens) {
      if (tok.type == TokenType::IDENTIFIER) {
        nIdentifiers++;
        const auto &identifierData = lexer.identifierDatas[tok.idx];
        identifierLengthTotal += identifierData.name.size();
        continue;
      }
      if (tok.type == TokenType::NUMBER) {
        nNumbers++;
        const auto &numberData = lexer.numberDatas[tok.idx];
        numberLengthTotal += numberData.asString.size();
      }
      if (tok.type != TokenType::STRING) {
        continue;
      }
      const auto &data = lexer.stringDatas[tok.idx];
      stringLengths.push_back(data.str.size());
    }
    pairs.emplace_back(contents.size(), lexer.tokens.size());
  }
  auto [slope, yIntercept] = computeLinearEquation(pairs);
  std::cerr << std::format("f(fileSize)={}x + {}", slope, yIntercept)
            << std::endl;
  auto sumStringLengths =
      std::accumulate(stringLengths.begin(), stringLengths.end(), (size_t)0);
  auto stringLengthAverage =
      (double)sumStringLengths / (double)stringLengths.size();
  std::cerr << std::format("{} strings, {} total length, {} average",
                           stringLengths.size(), sumStringLengths,
                           stringLengthAverage)
            << std::endl;
  auto sumPercentages = std::accumulate(deviationsInPercent.begin(),
                                        deviationsInPercent.end(), 0.0);
  auto percentagesAverage = sumPercentages / (double)deviationsInPercent.size();
  std::cerr << std::format("Average deviation from expected in %: {}%",
                           percentagesAverage)
            << std::endl;
  std::cerr << std::format(
                   "totalRealTokens / totalExpectedTokens = {} / {} = {}",
                   totalRealTokens, totalExpectedTokens,
                   ((double)totalRealTokens) / (double)totalExpectedTokens)
            << std::endl;
  std::cerr << std::format("Total files: {}", totalFiles) << std::endl;
  std::cerr << std::format("Less than expected: {}", totalLessThanExpected)
            << std::endl;
  std::cerr << std::format("More than expected: {}", totalMoreThanExpected)
            << std::endl;
  std::cerr << std::format("Exact: {}", exact) << std::endl;
  std::cerr << std::format("Total chars/identifier: {}",
                           ((double)identifierLengthTotal) /
                               ((double)nIdentifiers))
            << std::endl;
  std::cerr << std::format("Total chars/number: {}",
                           ((double)numberLengthTotal) / ((double)nNumbers))
            << std::endl;
}
