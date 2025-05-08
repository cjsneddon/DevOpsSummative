package bpp.com.devops;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.junit.jupiter.api.Assertions.*;

class NameManagerTest {

    private NameManager testObject;

    @BeforeEach
    public void setup() {
        testObject = new NameManager();
    }

    @Test
    public void testCreateName() {
        String name = testObject.createName();
        assertNotNull(name, "Name should not be null");
        assertEquals("Secret Squirrel", name, "Name does not match");
    }

    //Parameterized Test - Valid Name Cases
    @ParameterizedTest
    @ValueSource(strings = { "Secret Squirrel", "Hidden Hedgehog", "Mysterious Meerkat" })
    public void testCreateName_ValidValues(String expectedName) {
        String name = testObject.createName();
        assertNotNull(name, "Name should not be null");
        assertEquals(expectedName, name, "Unexpected name returned");
    }

    //Edge Case Test - Unexpected Values
    @Test
    public void testCreateName_UnexpectedCharacters() {
        String name = testObject.createName();
        assertTrue(name.matches("[A-Za-z\\s]+"), "Name contains unexpected characters");
    }
}